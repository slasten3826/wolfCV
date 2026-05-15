local config_mod = require("core.config")
local fs = require("core.fs")
local ids = require("core.ids")
local reports = require("reports.write")
local scan = require("stages.scan")
local classify = require("stages.classify")
local extract_evidence = require("stages.extract_evidence")
local build_claims = require("stages.build_claims")
local machinecv = require("reports.machinecv")
local stage_runner = require("runtime.stage_runner")

local M = {}

local function repo_index_by_id(repositories)
  local map = {}
  for _, repo in ipairs(repositories) do
    map[repo.repo_id] = repo
  end
  return map
end

local function slurp_excerpt(full_path, max_chars)
  local ok, content = pcall(fs.read_file, full_path)
  if not ok then
    return nil, "unreadable file"
  end

  if #content > max_chars then
    content = content:sub(1, max_chars)
  end

  return content, nil
end

local function evidence_candidates(classified, repositories, limits)
  local repo_map = repo_index_by_id(repositories)
  local candidates = {}

  for _, artifact in ipairs(classified) do
    if artifact.visibility == "normal" and artifact.class ~= "META" then
        local repo = repo_map[artifact.repo_id]
      if repo then
        local rel = artifact.path:gsub("^%./", "")
        local full_path = fs.join(repo.local_path, rel)
        local excerpt, read_error = slurp_excerpt(full_path, limits.source_excerpt_chars)
        candidates[#candidates + 1] = {
          artifact_id = artifact.artifact_id,
          repo_id = artifact.repo_id,
          repo_name = repo.repo_name,
          path = artifact.path,
          class = artifact.class,
          language = artifact.language,
          summary = artifact.summary,
          role_tags = artifact.role_tags,
          confidence = artifact.confidence,
          source_excerpt = excerpt,
          source_error = read_error,
        }
      end
    end
  end

  table.sort(candidates, function(a, b)
    if a.class == b.class then
      return a.path < b.path
    end
    return a.class < b.class
  end)

  return candidates
end

local function chunked(items, size)
  local batches = {}
  local index = 1
  while index <= #items do
    local batch = {}
    for i = index, math.min(index + size - 1, #items) do
      batch[#batch + 1] = items[i]
    end
    batches[#batches + 1] = batch
    index = index + size
  end
  return batches
end

local function chunked_by_chars(items, count_limit, char_limit, measure)
  local batches = {}
  local current = {}
  local current_chars = 0

  for _, item in ipairs(items) do
    local item_chars = measure(item)
    local would_overflow_count = #current >= count_limit
    local would_overflow_chars = (#current > 0) and (current_chars + item_chars > char_limit)

    if would_overflow_count or would_overflow_chars then
      batches[#batches + 1] = current
      current = {}
      current_chars = 0
    end

    current[#current + 1] = item
    current_chars = current_chars + item_chars
  end

  if #current > 0 then
    batches[#batches + 1] = current
  end

  return batches
end

local function stage_with_batch_name(stage, batch_label)
  local cloned = {}
  for key, value in pairs(stage) do
    cloned[key] = value
  end
  cloned.name = stage.name .. "_" .. batch_label
  return cloned
end

local function is_truncation_error(err)
  return type(err) == "string" and err:find("truncated", 1, true) ~= nil
end

local function run_single_batch(stage, input_key, batch, runtime_cfg, out_dir, extras, batch_label)
  local input_packet = {}
  if extras then
    for key, value in pairs(extras) do
      input_packet[key] = value
    end
  end
  input_packet[input_key] = batch

  local batch_stage = stage_with_batch_name(stage, batch_label)
  return stage_runner.run(batch_stage, input_packet, runtime_cfg, out_dir)
end

local function split_batch(batch)
  local midpoint = math.floor(#batch / 2)
  local left = {}
  local right = {}

  for i = 1, midpoint do
    left[#left + 1] = batch[i]
  end
  for i = midpoint + 1, #batch do
    right[#right + 1] = batch[i]
  end

  return left, right
end

local function run_batch_with_retry(stage, input_key, batch, runtime_cfg, out_dir, extras, batch_label)
  local result, err = run_single_batch(stage, input_key, batch, runtime_cfg, out_dir, extras, batch_label)
  if result then
    return result
  end

  if is_truncation_error(err) and #batch > 1 then
    local left, right = split_batch(batch)
    local merged = {}
    local left_result = run_batch_with_retry(stage, input_key, left, runtime_cfg, out_dir, extras, batch_label .. "_a")
    local right_result = run_batch_with_retry(stage, input_key, right, runtime_cfg, out_dir, extras, batch_label .. "_b")

    for _, item in ipairs(left_result) do
      merged[#merged + 1] = item
    end
    for _, item in ipairs(right_result) do
      merged[#merged + 1] = item
    end
    return merged
  end

  error(err)
end

local function run_stage_batches(stage, input_key, items, runtime_cfg, out_dir, extras, batch_size, batches_override)
  local merged = {}
  local batches = batches_override or chunked(items, batch_size)

  for batch_index, batch in ipairs(batches) do
    local result = run_batch_with_retry(
      stage,
      input_key,
      batch,
      runtime_cfg,
      out_dir,
      extras,
      string.format("batch_%02d", batch_index)
    )
    for _, item in ipairs(result) do
      merged[#merged + 1] = item
    end
  end

  return merged
end

local function normalize_evidence_ids(items)
  local seen = {}
  for index, item in ipairs(items) do
    local first_source = (item.source_artifacts and item.source_artifacts[1]) or ("item_" .. tostring(index))
    local assigned = item.evidence_id
    if type(assigned) ~= "string" or assigned == "" or seen[assigned] then
      assigned = ids.evidence_id(first_source, index)
      item.evidence_id = assigned
    end
    seen[assigned] = true
  end
end

local function normalize_claim_ids(items)
  local seen = {}
  for index, item in ipairs(items) do
    local first_tag = (item.normalized_skill_tags and item.normalized_skill_tags[1]) or "general"
    local assigned = item.claim_id
    if type(assigned) ~= "string" or assigned == "" or seen[assigned] then
      assigned = ids.claim_id(first_tag, index)
      item.claim_id = assigned
    end
    seen[assigned] = true
  end
end

function M.run_scan(config)
  local scan_result = scan.run(config)
  reports.write_json(fs.join(config.out, "repository_index.json"), scan_result.repositories)
  reports.write_json(fs.join(config.out, "artifacts.json"), scan_result.artifacts)
  reports.write_text(fs.join(config.out, "scan_summary.txt"), scan.build_summary(scan_result))
  return scan_result
end

function M.run_classify(config, scan_result)
  local runtime_cfg = config_mod.default_runtime()
  local limits = config_mod.pipeline_limits()
  local stage = classify.stage()
  local classified = run_stage_batches(
    stage,
    "artifacts",
    scan_result.artifacts,
    runtime_cfg,
    config.out,
    nil,
    limits.classify_batch_size
  )
  reports.write_json(fs.join(config.out, "classified_artifacts.json"), classified)
  return classified, runtime_cfg
end

function M.run_extract_evidence(config, repositories, classified, runtime_cfg)
  local limits = config_mod.pipeline_limits()
  local stage = extract_evidence.stage()
  local evidence_input = {
    artifacts = evidence_candidates(classified, repositories, limits),
  }
  local evidence_batches = chunked_by_chars(
    evidence_input.artifacts,
    limits.evidence_batch_size,
    limits.evidence_prompt_chars,
    function(item)
      return #(item.source_excerpt or "") + #(item.summary or "") + #(item.path or "") + 256
    end
  )
  local evidence = run_stage_batches(
    stage,
    "artifacts",
    evidence_input.artifacts,
    runtime_cfg,
    config.out,
    nil,
    limits.evidence_batch_size,
    evidence_batches
  )
  normalize_evidence_ids(evidence)
  reports.write_json(fs.join(config.out, "evidence_map.json"), evidence)
  return evidence
end

function M.run_build_claims(config, evidence, runtime_cfg)
  local limits = config_mod.pipeline_limits()
  local stage = build_claims.stage()
  local extras = {
    notes = config.notes and fs.read_file(config.notes) or nil,
    forbidden_claims = config.forbidden_claims and fs.read_file(config.forbidden_claims) or nil,
  }
  local claims = run_stage_batches(
    stage,
    "evidence",
    evidence,
    runtime_cfg,
    config.out,
    extras,
    limits.claim_batch_size
  )
  normalize_claim_ids(claims)
  reports.write_json(fs.join(config.out, "claims.json"), claims)
  reports.write_text(fs.join(config.out, "machinecv.md"), machinecv.render(evidence, claims))
  return claims
end

function M.run_truth(config)
  local scan_result = M.run_scan(config)
  local classified, runtime_cfg = M.run_classify(config, scan_result)
  local evidence = M.run_extract_evidence(config, scan_result.repositories, classified, runtime_cfg)
  local claims = M.run_build_claims(config, evidence, runtime_cfg)

  return {
    repositories = scan_result.repositories,
    artifacts = scan_result.artifacts,
    classified_artifacts = classified,
    evidence = evidence,
    claims = claims,
    runtime = runtime_cfg,
  }
end

return M
