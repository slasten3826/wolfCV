local config_mod = require("core.config")
local fs = require("core.fs")
local ids = require("core.ids")
local json = require("core.json")
local reports = require("reports.write")
local scan = require("stages.scan")
local classify = require("stages.classify")
local extract_evidence = require("stages.extract_evidence")
local build_claims = require("stages.build_claims")
local parse_vacancy = require("stages.parse_vacancy")
local translate = require("stages.translate")
local guard = require("stages.guard")
local machinecv = require("reports.machinecv")
local wolfcv_draft = require("reports.wolfcv_draft")
local guard_report = require("reports.guard_report")
local wolfcv = require("reports.wolfcv")
local stage_runner = require("runtime.stage_runner")

local M = {}

local function repo_index_by_id(repositories)
  local map = {}
  for _, repo in ipairs(repositories) do
    map[repo.repo_id] = repo
  end
  return map
end

local function claim_index_by_id(claims)
  local map = {}
  for _, claim in ipairs(claims) do
    map[claim.claim_id] = claim
  end
  return map
end

local function evidence_index_by_id(evidence)
  local map = {}
  for _, item in ipairs(evidence) do
    map[item.evidence_id] = item
  end
  return map
end

local function subset_draft_for_claims(draft, claim_ids)
  local keep = {}
  for _, claim_id in ipairs(claim_ids or {}) do
    keep[claim_id] = true
  end

  local bullets = {}
  for _, bullet in ipairs(draft.project_bullets or {}) do
    local first_claim_id = bullet.claim_ids and bullet.claim_ids[1] or nil
    if first_claim_id and keep[first_claim_id] then
      bullets[#bullets + 1] = bullet
    end
  end

  return {
    cvdraft_id = draft.cvdraft_id,
    vacancy_id = draft.vacancy_id,
    summary = draft.summary,
    role_title = draft.role_title,
    skill_blocks = draft.skill_blocks,
    project_bullets = bullets,
    claim_ids = claim_ids,
    target_mode = draft.target_mode,
  }
end

local function slurp_excerpt(full_path, max_chars)
  local ok, content = pcall(fs.read_file, full_path)
  if not ok then
    return nil, "unreadable file"
  end

  if #content > max_chars then
    content = content:sub(1, max_chars)
  end

  if utf8 and utf8.len and utf8.len(content) == nil then
    return nil, "non-utf8 source omitted"
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

local FAST_PATH_CLASS = {
  DOCS = true,
  INDEX = true,
  CONFIG = true,
  TEST = true,
}

local function stage_with_batch_name(stage, batch_label)
  local cloned = {}
  for key, value in pairs(stage) do
    cloned[key] = value
  end
  cloned.name = stage.name .. "_" .. batch_label
  return cloned
end

local function read_json_file(path)
  if not fs.exists(path) then
    return nil
  end

  local read_ok, content = pcall(fs.read_file, path)
  if not read_ok then
    return nil
  end

  local decode_ok, decoded = pcall(json.decode, content)
  if not decode_ok then
    return nil
  end

  return decoded
end

local function load_batch_trace_result(stage_name, out_dir, batch_label)
  local trace_dir = fs.join(out_dir, "traces", stage_name .. "_" .. batch_label)
  local validation = read_json_file(fs.join(trace_dir, "validation.json"))
  local parsed = read_json_file(fs.join(trace_dir, "parsed_output.json"))

  if type(validation) == "table" and validation.ok == true and type(parsed) == "table" then
    return parsed
  end

  local left = load_batch_trace_result(stage_name, out_dir, batch_label .. "_a")
  local right = load_batch_trace_result(stage_name, out_dir, batch_label .. "_b")
  if type(left) == "table" and type(right) == "table" then
    local merged = {}
    for _, item in ipairs(left) do
      merged[#merged + 1] = item
    end
    for _, item in ipairs(right) do
      merged[#merged + 1] = item
    end
    return merged
  end

  return nil
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
  local resumed = load_batch_trace_result(stage.name, out_dir, batch_label)
  if resumed then
    return resumed
  end

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

local function read_optional_file(path)
  if not path then
    return nil
  end
  return fs.read_file(path)
end

local function require_target(config)
  if not config.target or config.target == "" then
    error("target vacancy file is required for this command")
  end
  if not fs.exists(config.target) then
    error("target vacancy file does not exist: " .. config.target)
  end
  return config.target
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

local function is_low_value_claim_evidence(item)
  if item.evidence_type ~= "DOCS" or item.strength ~= "weak" then
    return false
  end

  local statement = (item.statement or ""):lower()
  local has_skills = type(item.supports_skills) == "table" and #item.supports_skills > 0
  if has_skills then
    return false
  end

  return statement:find("content unavailable", 1, true)
    or statement:find("could not be read", 1, true)
    or statement:find("document exists", 1, true)
    or statement:find("artifact exists", 1, true)
    or statement:find("cargo.lock file exists", 1, true)
    or statement:find("no extractable evidence", 1, true)
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
  local fast = {}
  local machine = {}

  for _, artifact in ipairs(scan_result.artifacts) do
    if artifact.visibility == "normal" and FAST_PATH_CLASS[artifact.class] then
      fast[#fast + 1] = artifact
    else
      machine[#machine + 1] = artifact
    end
  end

  local machine_batches = chunked_by_chars(
    machine,
    limits.classify_batch_size,
    limits.classify_prompt_chars,
    function(item)
      return #(item.path or "") + #(item.summary or "") + 256
    end
  )

  local classified = {}
  for _, item in ipairs(fast) do
    classified[#classified + 1] = item
  end

  if #machine > 0 then
    local machine_classified = run_stage_batches(
      stage,
      "artifacts",
      machine,
      runtime_cfg,
      config.out,
      nil,
      limits.classify_batch_size,
      machine_batches
    )
    for _, item in ipairs(machine_classified) do
      classified[#classified + 1] = item
    end
  end

  table.sort(classified, function(a, b)
    if a.repo_id == b.repo_id then
      return a.path < b.path
    end
    return a.repo_id < b.repo_id
  end)

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
  local filtered_evidence = {}
  for _, item in ipairs(evidence) do
    if not is_low_value_claim_evidence(item) then
      filtered_evidence[#filtered_evidence + 1] = item
    end
  end
  local claims = run_stage_batches(
    stage,
    "evidence",
    filtered_evidence,
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

function M.run_parse_vacancy(config, runtime_cfg)
  local stage = parse_vacancy.stage()
  local target_path = require_target(config)
  local input_packet = {
    raw_text_path = target_path,
    raw_text = fs.read_file(target_path),
    notes = read_optional_file(config.notes),
  }

  local vacancy_map = assert(stage_runner.run(stage, input_packet, runtime_cfg, config.out))
  vacancy_map = parse_vacancy.normalize_output(vacancy_map, input_packet)
  local ok, err = stage.validate_output(vacancy_map)
  if not ok then
    error(err)
  end
  reports.write_json(fs.join(config.out, "vacancy_map.json"), vacancy_map)
  return vacancy_map
end

function M.run_translate(config, claims, vacancy_map, runtime_cfg)
  local stage = translate.stage()
  local safe_claims = {}
  for _, claim in ipairs(claims) do
    if claim.safe_for_cv and claim.support_level ~= "FORBIDDEN" and claim.support_level ~= "UNSUPPORTED" then
      safe_claims[#safe_claims + 1] = claim
    end
  end

  local input_packet = {
    claims = safe_claims,
    vacancy_map = vacancy_map,
    notes = read_optional_file(config.notes),
  }

  local draft = assert(stage_runner.run(stage, input_packet, runtime_cfg, config.out))
  draft = translate.normalize_output(draft, input_packet)
  local ok, err = stage.validate_output(draft)
  if not ok then
    error(err)
  end

  reports.write_json(fs.join(config.out, "cv_draft.json"), draft)
  reports.write_text(fs.join(config.out, "wolfcv_draft.md"), wolfcv_draft.render(vacancy_map, draft))
  return draft
end

function M.run_guard(config, claims, evidence, vacancy_map, draft, runtime_cfg)
  local limits = config_mod.pipeline_limits()
  local stage = guard.stage()
  local claim_map = claim_index_by_id(claims)
  local evidence_map = evidence_index_by_id(evidence)
  local selected_claims = {}
  local seen = {}

  for _, claim_id in ipairs(draft.claim_ids or {}) do
    local claim = claim_map[claim_id]
    if claim and not seen[claim_id] then
      selected_claims[#selected_claims + 1] = claim
      seen[claim_id] = true
    end
  end

  local extras = {
    draft = draft,
    vacancy_map = vacancy_map,
    forbidden_claims = read_optional_file(config.forbidden_claims),
  }

  local results = {}
  local batches = chunked(selected_claims, limits.guard_batch_size)
  for batch_index, batch in ipairs(batches) do
    local batch_claim_ids = {}
    local batch_claim_id_map = {}
    local relevant_evidence = {}
    local evidence_seen = {}
    for _, claim in ipairs(batch) do
      batch_claim_ids[#batch_claim_ids + 1] = claim.claim_id
      batch_claim_id_map[claim.claim_id] = true
      for _, evidence_id in ipairs(claim.supporting_evidence_ids or {}) do
        local item = evidence_map[evidence_id]
        if item and not evidence_seen[evidence_id] then
          relevant_evidence[#relevant_evidence + 1] = item
          evidence_seen[evidence_id] = true
        end
      end
    end

    local batch_result = run_batch_with_retry(
      stage,
      "claims",
      batch,
      runtime_cfg,
      config.out,
      {
        draft = subset_draft_for_claims(extras.draft, batch_claim_ids),
        vacancy_map = extras.vacancy_map,
        forbidden_claims = extras.forbidden_claims,
        evidence = relevant_evidence,
      },
      string.format("batch_%02d", batch_index)
    )

    local accepted = 0
    for _, item in ipairs(batch_result) do
      if batch_claim_id_map[item.claim_id] then
        results[#results + 1] = item
        accepted = accepted + 1
      end
    end
    if accepted ~= #batch then
      error("guard stage returned incomplete result set for batch " .. tostring(batch_index))
    end
  end

  reports.write_json(fs.join(config.out, "guard_results.json"), results)
  reports.write_text(fs.join(config.out, "evidence_guard_report.md"), guard_report.render(results))
  reports.write_text(fs.join(config.out, "wolfcv.md"), wolfcv.render(vacancy_map, draft, results))
  return results
end

function M.run_full(config)
  local truth = M.run_truth(config)
  local vacancy_map = M.run_parse_vacancy(config, truth.runtime)
  local draft = M.run_translate(config, truth.claims, vacancy_map, truth.runtime)
  local guard_results = M.run_guard(config, truth.claims, truth.evidence, vacancy_map, draft, truth.runtime)

  truth.vacancy_map = vacancy_map
  truth.cv_draft = draft
  truth.guard_results = guard_results
  return truth
end

return M
