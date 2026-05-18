local config_mod = require("core.config")
local fs = require("core.fs")
local ids = require("core.ids")
local json = require("core.json")
local memory_trace = require("core.memory_trace")
local reports = require("reports.write")
local scan = require("stages.scan")
local classify = require("stages.classify")
local extract_evidence = require("stages.extract_evidence")
local build_claims = require("stages.build_claims")
local parse_vacancy = require("stages.parse_vacancy")
local select_batches = require("stages.select_batches")
local translate = require("stages.translate")
local guard = require("stages.guard")
local machinecv = require("reports.machinecv")
local vacancy_diagnosis = require("reports.vacancy_diagnosis")
local wolfcv_draft = require("reports.wolfcv_draft")
local guard_report = require("reports.guard_report")
local wolfcv = require("reports.wolfcv")
local hhcv = require("reports.hhcv")
local start_here = require("reports.start_here")
local batch_selection_report = require("reports.batch_selection")
local stage_runner = require("runtime.stage_runner")

local M = {}
local run_batch_with_retry

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

local function basename(path)
  return (path and path:match("([^/]+)$")) or path or ""
end

local function is_readme_path(path)
  local name = basename(path):lower()
  return name == "readme" or name:match("^readme[%._-]")
end

local function include_in_evidence(artifact, config)
  if artifact.visibility ~= "normal" or artifact.class == "META" then
    return false
  end

  if config.no_docs and artifact.class == "DOCS" and not is_readme_path(artifact.path) then
    return false
  end

  return true
end

local function evidence_candidates(config, classified, repositories, limits)
  local repo_map = repo_index_by_id(repositories)
  local candidates = {}

  for _, artifact in ipairs(classified) do
    if include_in_evidence(artifact, config) then
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

local function count_by(items, key_fn)
  local counts = {}
  for _, item in ipairs(items) do
    local key = key_fn(item)
    counts[key] = (counts[key] or 0) + 1
  end
  return counts
end

local function counts_to_list(counts)
  local items = {}
  for key, count in pairs(counts) do
    items[#items + 1] = {
      key = key,
      count = count,
    }
  end
  table.sort(items, function(a, b)
    if a.count == b.count then
      return a.key < b.key
    end
    return a.count > b.count
  end)
  return items
end

local function first_role_tag(item)
  local tags = item.role_tags or {}
  return tags[1] or "general"
end

local function planner_signal_tags_for(item)
  local out = {}
  local seen = {}
  local function push(value)
    if value and value ~= "" and not seen[value] then
      out[#out + 1] = value
      seen[value] = true
    end
  end

  for _, tag in ipairs(item.role_tags or {}) do
    push(tag)
  end

  local path = (item.path or ""):lower()
  local path_signals = {
    scenario = "scenario",
    smoke = "smoke",
    headless = "headless",
    bench = "bench",
    invariant = "invariant",
    autoplay = "autoplay",
    cli = "cli",
    sim = "simulation",
    runner = "runner",
    inspect = "inspection",
  }
  for token, tag in pairs(path_signals) do
    if path:find(token, 1, true) then
      push(tag)
    end
  end

  if is_readme_path(item.path) then
    push("readme")
  end

  table.sort(out)
  return out
end

local function planner_cluster_for(item)
  return table.concat({
    item.repo_id or "repo",
    item.class or "DOCS",
    first_role_tag(item),
  }, ":")
end

local function planner_priority_for(item)
  local score = 0
  local class_name = item.class or "DOCS"
  local tags = item.role_tags or {}
  local path = (item.path or ""):lower()

  local class_weight = {
    CODE = 10,
    TEST = 9,
    SPEC = 8,
    PROTOCOL = 8,
    RESEARCH = 7,
    INDEX = 6,
    CONFIG = 4,
    DOCS = 3,
    MEDIA = 2,
  }
  score = score + (class_weight[class_name] or 1)

  local tag_bonus = {
    verification = 4,
    runtime = 3,
    implementation = 3,
    protocol = 3,
    formal_spec = 2,
    research = 2,
    configuration = 1,
    documentation = 0,
  }
  for _, tag in ipairs(tags) do
    score = score + (tag_bonus[tag] or 0)
  end

  local path_bonus = {
    smoke = 4,
    scenario = 4,
    headless = 4,
    bench = 3,
    invariant = 4,
    cli = 3,
    test = 3,
    runner = 2,
    autoplay = 2,
  }
  for token, bonus in pairs(path_bonus) do
    if path:find(token, 1, true) then
      score = score + bonus
    end
  end

  if is_readme_path(item.path) then
    score = score + 3
  end

  return score
end

local function include_in_batch_plan(config, artifact)
  return include_in_evidence(artifact, config)
end

local function planner_candidate_items(config, artifacts)
  local candidates = {}
  for _, artifact in ipairs(artifacts) do
    if include_in_batch_plan(config, artifact) then
      candidates[#candidates + 1] = {
        artifact_id = artifact.artifact_id,
        repo_id = artifact.repo_id,
        path = artifact.path,
        class = artifact.class,
        summary = artifact.summary,
        role_tags = planner_signal_tags_for(artifact),
        confidence = artifact.confidence or 0.5,
        cluster_id = planner_cluster_for(artifact),
        planner_priority = planner_priority_for(artifact),
      }
    end
  end

  table.sort(candidates, function(a, b)
    if a.cluster_id == b.cluster_id then
      if a.planner_priority == b.planner_priority then
        return a.path < b.path
      end
      return a.planner_priority > b.planner_priority
    end
    return a.cluster_id < b.cluster_id
  end)

  return candidates
end

local function planner_batches(config, repositories, artifacts, limits)
  local repo_map = repo_index_by_id(repositories)
  local candidates = planner_candidate_items(config, artifacts)
  local grouped = {}
  local group_order = {}

  for _, item in ipairs(candidates) do
    if not grouped[item.cluster_id] then
      grouped[item.cluster_id] = {}
      group_order[#group_order + 1] = item.cluster_id
    end
    grouped[item.cluster_id][#grouped[item.cluster_id] + 1] = item
  end

  local plan = {}
  for _, cluster_id in ipairs(group_order) do
    local cluster_items = grouped[cluster_id]
    local batches = chunked_by_chars(
      cluster_items,
      limits.planning_batch_size,
      limits.planning_prompt_chars,
      function(item)
        return #(item.path or "") + #(item.summary or "") + 128
      end
    )

    for batch_index, batch in ipairs(batches) do
      local repo = repo_map[batch[1].repo_id] or {}
      local signal_seen = {}
      local class_seen = {}
      local artifact_ids = {}
      local representative_paths = {}
      local signal_tags = {}
      local class_mix = {}
      local priority_total = 0
      local estimated_chars = 0

      for _, item in ipairs(batch) do
        artifact_ids[#artifact_ids + 1] = item.artifact_id
        if #representative_paths < 4 then
          representative_paths[#representative_paths + 1] = item.path
        end
        priority_total = priority_total + (item.planner_priority or 0)
        estimated_chars = estimated_chars + #(item.path or "") + #(item.summary or "") + 128

        if not class_seen[item.class] then
          class_mix[#class_mix + 1] = item.class
          class_seen[item.class] = true
        end
        for _, tag in ipairs(item.role_tags or {}) do
          if not signal_seen[tag] then
            signal_tags[#signal_tags + 1] = tag
            signal_seen[tag] = true
          end
        end
      end

      table.sort(signal_tags)
      table.sort(class_mix)

      plan[#plan + 1] = {
        batch_id = ids.batch_id(cluster_id, batch_index),
        repo_id = batch[1].repo_id,
        repo_name = repo.repo_name or batch[1].repo_id,
        cluster_id = cluster_id,
        artifact_ids = artifact_ids,
        representative_paths = representative_paths,
        class_mix = class_mix,
        signal_tags = signal_tags,
        artifact_count = #batch,
        estimated_chars = estimated_chars,
        planner_priority = priority_total / math.max(#batch, 1),
      }
    end
  end

  table.sort(plan, function(a, b)
    if a.planner_priority == b.planner_priority then
      return a.batch_id < b.batch_id
    end
    return a.planner_priority > b.planner_priority
  end)

  return plan
end

local function select_batches_internal(config, vacancy_map, plan, selector_runtime, out_dir)
  local limits = config_mod.pipeline_limits()
  local stage = select_batches.stage()
  local selection_batches = chunked_by_chars(
    plan,
    limits.planning_batch_size,
    limits.planning_prompt_chars,
    function(item)
      return #(item.batch_id or "") + #(item.repo_name or "") + #(item.cluster_id or "")
        + #(table.concat(item.representative_paths or {}, ",")) + #(table.concat(item.signal_tags or {}, ","))
        + 256
    end
  )

  local selection = {}
  local selection_seen = {}
  for batch_index, batch in ipairs(selection_batches) do
    local batch_result = run_batch_with_retry(
      stage,
      "batch_plan",
      batch,
      selector_runtime,
      out_dir,
      {
        vacancy_map = vacancy_map,
      },
      string.format("batch_%02d", batch_index)
    )

    for _, item in ipairs(batch_result) do
      if item.batch_id and not selection_seen[item.batch_id] then
        selection[#selection + 1] = item
        selection_seen[item.batch_id] = true
      end
    end
  end

  return selection
end

local function selected_artifact_ids(batch_plan, selection)
  local keep_batches = {}
  for _, item in ipairs(selection or {}) do
    if item.decision == "read_now" or item.decision == "read_if_needed" then
      keep_batches[item.batch_id] = true
    end
  end

  local keep_ids = {}
  for _, batch in ipairs(batch_plan or {}) do
    if keep_batches[batch.batch_id] then
      for _, artifact_id in ipairs(batch.artifact_ids or {}) do
        keep_ids[artifact_id] = true
      end
    end
  end
  return keep_ids
end

local function filter_artifacts_by_id(artifacts, keep_ids)
  local filtered = {}
  for _, artifact in ipairs(artifacts or {}) do
    if keep_ids[artifact.artifact_id] then
      filtered[#filtered + 1] = artifact
    end
  end
  return filtered
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

  local left_trace_dir = fs.join(out_dir, "traces", stage_name .. "_" .. batch_label .. "_a")
  local right_trace_dir = fs.join(out_dir, "traces", stage_name .. "_" .. batch_label .. "_b")
  if not fs.is_dir(left_trace_dir) and not fs.is_dir(right_trace_dir) then
    return nil
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
  memory_trace.log(out_dir, "run_single_batch.before", {
    stage = stage.name,
    batch_label = batch_label,
    batch_size = #batch,
  })
  local input_packet = {}
  if extras then
    for key, value in pairs(extras) do
      input_packet[key] = value
    end
  end
  input_packet[input_key] = batch

  local batch_stage = stage_with_batch_name(stage, batch_label)
  local result, err = stage_runner.run(batch_stage, input_packet, runtime_cfg, out_dir)
  memory_trace.log(out_dir, "run_single_batch.after", {
    stage = stage.name,
    batch_label = batch_label,
    ok = result ~= nil,
    error = err or "",
  })
  return result, err
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

run_batch_with_retry = function(stage, input_key, batch, runtime_cfg, out_dir, extras, batch_label)
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
  memory_trace.log(out_dir, "run_stage_batches.start", {
    stage = stage.name,
    item_count = #items,
    batch_count = #batches,
  })

  for batch_index, batch in ipairs(batches) do
    memory_trace.log(out_dir, "run_stage_batches.batch_before", {
      stage = stage.name,
      batch_index = batch_index,
      batch_size = #batch,
    })
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
    memory_trace.log(out_dir, "run_stage_batches.batch_after", {
      stage = stage.name,
      batch_index = batch_index,
      merged_count = #merged,
    })
  end

  memory_trace.log(out_dir, "run_stage_batches.done", {
    stage = stage.name,
    merged_count = #merged,
  })
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
  memory_trace.log(config.out, "run_scan.start")
  local scan_result = scan.run(config)
  memory_trace.log(config.out, "run_scan.after_scan", {
    repo_count = #scan_result.repositories,
    artifact_count = #scan_result.artifacts,
  })
  reports.write_json(fs.join(config.out, "repository_index.json"), scan_result.repositories)
  reports.write_json(fs.join(config.out, "artifacts.json"), scan_result.artifacts)
  reports.write_text(fs.join(config.out, "scan_summary.txt"), scan.build_summary(scan_result))
  memory_trace.log(config.out, "run_scan.done")
  return scan_result
end

function M.run_preflight(config)
  local scan_result = M.run_scan(config)
  local limits = config_mod.pipeline_limits()

  local fast = {}
  local machine = {}
  for _, artifact in ipairs(scan_result.artifacts) do
    if artifact.visibility == "normal" and FAST_PATH_CLASS[artifact.class] then
      fast[#fast + 1] = artifact
    else
      machine[#machine + 1] = artifact
    end
  end

  local classify_batches = chunked_by_chars(
    machine,
    limits.classify_batch_size,
    limits.classify_prompt_chars,
    function(item)
      return #(item.path or "") + #(item.summary or "") + 256
    end
  )

  local evidence_items = evidence_candidates(config, scan_result.artifacts, scan_result.repositories, limits)
  local evidence_batches = chunked_by_chars(
    evidence_items,
    limits.evidence_batch_size,
    limits.evidence_prompt_chars,
    function(item)
      return #(item.source_excerpt or "") + #(item.summary or "") + #(item.path or "") + 256
    end
  )

  local result = {
    repos = #scan_result.repositories,
    artifacts = #scan_result.artifacts,
    classify = {
      fast_path_artifacts = #fast,
      machine_artifacts = #machine,
      estimated_batches = #classify_batches,
    },
    evidence = {
      candidates = #evidence_items,
      estimated_batches = #evidence_batches,
    },
    artifact_classes = counts_to_list(count_by(scan_result.artifacts, function(item)
      return item.class or "unknown"
    end)),
    evidence_classes = counts_to_list(count_by(evidence_items, function(item)
      return item.class or "unknown"
    end)),
    limits = {
      classify_batch_size = limits.classify_batch_size,
      classify_prompt_chars = limits.classify_prompt_chars,
      evidence_batch_size = limits.evidence_batch_size,
      evidence_prompt_chars = limits.evidence_prompt_chars,
      source_excerpt_chars = limits.source_excerpt_chars,
      no_docs = config.no_docs or false,
    },
    estimate_quality = "approximate_from_scan",
  }

  reports.write_json(fs.join(config.out, "preflight.json"), result)
  return result
end

function M.run_batch_plan(config, scan_result)
  scan_result = scan_result or M.run_scan(config)
  local limits = config_mod.pipeline_limits()
  local plan = planner_batches(config, scan_result.repositories, scan_result.artifacts, limits)
  reports.write_json(fs.join(config.out, "batch_plan.json"), plan)
  return plan, scan_result
end

function M.run_classify(config, scan_result)
  memory_trace.log(config.out, "run_classify.start", {
    artifact_count = #scan_result.artifacts,
  })
  local runtime_cfg = config_mod.default_runtime("classify")
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
  memory_trace.log(config.out, "run_classify.after_split", {
    fast_count = #fast,
    machine_count = #machine,
  })

  local machine_batches = chunked_by_chars(
    machine,
    limits.classify_batch_size,
    limits.classify_prompt_chars,
    function(item)
      return #(item.path or "") + #(item.summary or "") + 256
    end
  )
  memory_trace.log(config.out, "run_classify.after_batching", {
    machine_batch_count = #machine_batches,
  })

  local classified = {}
  for _, item in ipairs(fast) do
    classified[#classified + 1] = item
  end
  memory_trace.log(config.out, "run_classify.after_fast_copy", {
    classified_count = #classified,
  })

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
    memory_trace.log(config.out, "run_classify.after_machine_merge", {
      classified_count = #classified,
    })
  end

  table.sort(classified, function(a, b)
    if a.repo_id == b.repo_id then
      return a.path < b.path
    end
    return a.repo_id < b.repo_id
  end)
  memory_trace.log(config.out, "run_classify.after_sort", {
    classified_count = #classified,
  })

  reports.write_json(fs.join(config.out, "classified_artifacts.json"), classified)
  memory_trace.log(config.out, "run_classify.done", {
    classified_count = #classified,
  })
  return classified, runtime_cfg
end

function M.run_extract_evidence(config, repositories, classified, runtime_cfg)
  runtime_cfg = runtime_cfg or config_mod.default_runtime("extract_evidence")
  local limits = config_mod.pipeline_limits()
  local stage = extract_evidence.stage()
  local evidence_input = {
    artifacts = evidence_candidates(config, classified, repositories, limits),
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
  runtime_cfg = runtime_cfg or config_mod.default_runtime("build_claims")
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
  local classified, classify_runtime = M.run_classify(config, scan_result)
  local evidence_runtime = config_mod.default_runtime("extract_evidence")
  local claims_runtime = config_mod.default_runtime("build_claims")
  local evidence = M.run_extract_evidence(config, scan_result.repositories, classified, evidence_runtime)
  local claims = M.run_build_claims(config, evidence, claims_runtime)

  local runtime = {
    provider = (classify_runtime.provider == evidence_runtime.provider and evidence_runtime.provider == claims_runtime.provider)
      and classify_runtime.provider or "mixed",
    model = (classify_runtime.model == evidence_runtime.model and evidence_runtime.model == claims_runtime.model)
      and classify_runtime.model or "mixed",
    stages = {
      classify = classify_runtime,
      extract_evidence = evidence_runtime,
      build_claims = claims_runtime,
    },
  }

  return {
    repositories = scan_result.repositories,
    artifacts = scan_result.artifacts,
    classified_artifacts = classified,
    evidence = evidence,
    claims = claims,
    runtime = runtime,
  }
end

function M.run_select_batches(config)
  local scan_result = M.run_scan(config)
  local plan = M.run_batch_plan(config, scan_result)
  local vacancy_runtime = config_mod.default_runtime("parse_vacancy")
  local selector_runtime = config_mod.default_runtime("select_batches")
  local vacancy_map = M.run_parse_vacancy(config, vacancy_runtime)
  local selection = select_batches_internal(config, vacancy_map, plan, selector_runtime, config.out)

  reports.write_json(fs.join(config.out, "batch_selection.json"), selection)
  reports.write_text(
    fs.join(config.out, "batch_selection.md"),
    batch_selection_report.render(vacancy_map, plan, selection)
  )

  return {
    repositories = scan_result.repositories,
    artifacts = scan_result.artifacts,
    batch_plan = plan,
    batch_selection = selection,
    vacancy_map = vacancy_map,
    runtime = {
      provider = (vacancy_runtime.provider == selector_runtime.provider) and vacancy_runtime.provider or "mixed",
      model = (vacancy_runtime.model == selector_runtime.model) and vacancy_runtime.model or "mixed",
      stages = {
        parse_vacancy = vacancy_runtime,
        select_batches = selector_runtime,
      },
    },
  }
end

function M.run_selected_full(config)
  local scan_result = M.run_scan(config)
  local plan = M.run_batch_plan(config, scan_result)
  local vacancy_runtime = config_mod.default_runtime("parse_vacancy")
  local selector_runtime = config_mod.default_runtime("select_batches")
  local evidence_runtime = config_mod.default_runtime("extract_evidence")
  local claims_runtime = config_mod.default_runtime("build_claims")
  local translate_runtime = config_mod.default_runtime("translate")
  local guard_runtime = config_mod.default_runtime("guard")

  local vacancy_map = M.run_parse_vacancy(config, vacancy_runtime)
  local selection = select_batches_internal(config, vacancy_map, plan, selector_runtime, config.out)
  reports.write_json(fs.join(config.out, "batch_selection.json"), selection)
  reports.write_text(
    fs.join(config.out, "batch_selection.md"),
    batch_selection_report.render(vacancy_map, plan, selection)
  )

  local keep_ids = selected_artifact_ids(plan, selection)
  local filtered_scan = {
    repositories = scan_result.repositories,
    artifacts = filter_artifacts_by_id(scan_result.artifacts, keep_ids),
  }
  reports.write_json(fs.join(config.out, "selected_artifacts.json"), filtered_scan.artifacts)

  local classified, classify_runtime = M.run_classify(config, filtered_scan)
  local evidence = M.run_extract_evidence(config, filtered_scan.repositories, classified, evidence_runtime)
  local claims = M.run_build_claims(config, evidence, claims_runtime)
  local draft = M.run_translate(config, claims, vacancy_map, translate_runtime)
  local guard_results = M.run_guard(config, claims, evidence, vacancy_map, draft, guard_runtime)

  local result = {
    repositories = filtered_scan.repositories,
    artifacts = filtered_scan.artifacts,
    classified_artifacts = classified,
    evidence = evidence,
    claims = claims,
    vacancy_map = vacancy_map,
    cv_draft = draft,
    guard_results = guard_results,
    batch_plan = plan,
    batch_selection = selection,
    runtime = {
      provider = "mixed",
      model = "mixed",
      stages = {
        classify = classify_runtime,
        extract_evidence = evidence_runtime,
        build_claims = claims_runtime,
        parse_vacancy = vacancy_runtime,
        select_batches = selector_runtime,
        translate = translate_runtime,
        guard = guard_runtime,
      },
    },
  }
  reports.write_text(fs.join(config.out, "START_HERE.md"), start_here.render(result))
  return result
end

function M.run_parse_vacancy(config, runtime_cfg)
  runtime_cfg = runtime_cfg or config_mod.default_runtime("parse_vacancy")
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
  reports.write_text(fs.join(config.out, "vacancy_diagnosis.md"), vacancy_diagnosis.render(vacancy_map))
  return vacancy_map
end

function M.run_translate(config, claims, vacancy_map, runtime_cfg)
  runtime_cfg = runtime_cfg or config_mod.default_runtime("translate")
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
  runtime_cfg = runtime_cfg or config_mod.default_runtime("guard")
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
  reports.write_text(fs.join(config.out, "hhcv.md"), hhcv.render(vacancy_map, draft, results))
  return results
end

function M.run_full(config)
  local truth = M.run_truth(config)
  local vacancy_runtime = config_mod.default_runtime("parse_vacancy")
  local translate_runtime = config_mod.default_runtime("translate")
  local guard_runtime = config_mod.default_runtime("guard")
  local vacancy_map = M.run_parse_vacancy(config, vacancy_runtime)
  local draft = M.run_translate(config, truth.claims, vacancy_map, translate_runtime)
  local guard_results = M.run_guard(config, truth.claims, truth.evidence, vacancy_map, draft, guard_runtime)

  truth.vacancy_map = vacancy_map
  truth.cv_draft = draft
  truth.guard_results = guard_results
  truth.runtime.stages.parse_vacancy = vacancy_runtime
  truth.runtime.stages.translate = translate_runtime
  truth.runtime.stages.guard = guard_runtime
  reports.write_text(fs.join(config.out, "START_HERE.md"), start_here.render(truth))
  return truth
end

return M
