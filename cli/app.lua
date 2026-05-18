local parser = require("cli.parse")
local json = require("core.json")
local pipeline = require("core.pipeline")

local M = {}

local function usage()
  return table.concat({
    "usage:",
    "  lua main.lua scan --repos ./repo1 ./repo2 --out ./wolfcv-out",
    "  lua main.lua scan --github-profile slasten3826 --out ./wolfcv-out",
    "  lua main.lua preflight --repos ./repo1 ./repo2 --target ./vacancy.txt --out ./wolfcv-out",
    "  lua main.lua preflight --github-profile slasten3826 --exclude-repo planGOD --out ./wolfcv-out",
    "  lua main.lua select-batches --repos ./repo1 ./repo2 --target ./vacancy.txt --out ./wolfcv-out",
    "  lua main.lua run-selected --repos ./repo1 ./repo2 --target ./vacancy.txt --out ./wolfcv-out",
    "  lua main.lua classify --repos ./repo1 ./repo2 --out ./wolfcv-out",
    "  lua main.lua truth --repos ./repo1 ./repo2 --out ./wolfcv-out",
    "  lua main.lua parse-vacancy --target ./vacancy.txt --out ./wolfcv-out",
    "  lua main.lua translate --repos ./repo1 ./repo2 --target ./vacancy.txt --out ./wolfcv-out",
    "  lua main.lua guard --repos ./repo1 ./repo2 --target ./vacancy.txt --out ./wolfcv-out",
    "  lua main.lua run --repos ./repo1 ./repo2 --target ./vacancy.txt --out ./wolfcv-out",
    "  lua main.lua run --repos ./repo1 ./repo2 --target ./vacancy.txt --no-docs --out ./wolfcv-out",
  }, "\n")
end

function M.run(argv)
  local config = parser.parse(argv)

  if config.command == "help" then
    io.stdout:write(usage() .. "\n")
    return
  end

  if config.command == "scan" then
    local result = pipeline.run_scan(config)
    io.stdout:write(json.encode_pretty({
      command = "scan",
      repositories = #result.repositories,
      artifacts = #result.artifacts,
      github_profiles = #(config.github_profiles or {}),
      out = config.out,
    }) .. "\n")
  elseif config.command == "preflight" then
    local result = pipeline.run_preflight(config)
    io.stdout:write(json.encode_pretty({
      command = "preflight",
      repositories = result.repos,
      artifacts = result.artifacts,
      classify_machine_artifacts = result.classify.machine_artifacts,
      classify_estimated_batches = result.classify.estimated_batches,
      evidence_candidates = result.evidence.candidates,
      evidence_estimated_batches = result.evidence.estimated_batches,
      no_docs = result.limits.no_docs,
      estimate_quality = result.estimate_quality,
      out = config.out,
    }) .. "\n")
  elseif config.command == "select-batches" then
    local result = pipeline.run_select_batches(config)
    local counts = {
      read_now = 0,
      read_if_needed = 0,
      skip = 0,
    }
    for _, item in ipairs(result.batch_selection or {}) do
      if counts[item.decision] ~= nil then
        counts[item.decision] = counts[item.decision] + 1
      end
    end
    io.stdout:write(json.encode_pretty({
      command = "select-batches",
      repositories = #result.repositories,
      artifacts = #result.artifacts,
      planned_batches = #result.batch_plan,
      selected_read_now = counts.read_now,
      selected_read_if_needed = counts.read_if_needed,
      selected_skip = counts.skip,
      vacancy_id = result.vacancy_map and result.vacancy_map.vacancy_id or nil,
      provider = result.runtime.provider,
      model = result.runtime.model,
      out = config.out,
    }) .. "\n")
  elseif config.command == "run-selected" then
    local result = pipeline.run_selected_full(config)
    io.stdout:write(json.encode_pretty({
      command = "run-selected",
      repositories = #result.repositories,
      selected_artifacts = #result.artifacts,
      classified_artifacts = #result.classified_artifacts,
      evidence = #result.evidence,
      claims = #result.claims,
      planned_batches = #result.batch_plan,
      selected_batches = #result.batch_selection,
      vacancy_id = result.vacancy_map and result.vacancy_map.vacancy_id or nil,
      translated_claims = result.cv_draft and #result.cv_draft.claim_ids or nil,
      guard_results = result.guard_results and #result.guard_results or nil,
      provider = result.runtime.provider,
      model = result.runtime.model,
      out = config.out,
    }) .. "\n")
  elseif config.command == "classify" then
    local scan_result = pipeline.run_scan(config)
    local classified, runtime_cfg = pipeline.run_classify(config, scan_result)
    io.stdout:write(json.encode_pretty({
      command = "classify",
      repositories = #scan_result.repositories,
      artifacts = #scan_result.artifacts,
      classified_artifacts = #classified,
      github_profiles = #(config.github_profiles or {}),
      provider = runtime_cfg.provider,
      model = runtime_cfg.model,
      out = config.out,
    }) .. "\n")
  elseif config.command == "truth" or config.command == "run" then
    local result
    if config.command == "truth" then
      result = pipeline.run_truth(config)
    else
      result = pipeline.run_full(config)
    end
    io.stdout:write(json.encode_pretty({
      command = config.command,
      repositories = #result.repositories,
      artifacts = #result.artifacts,
      classified_artifacts = #result.classified_artifacts,
      evidence = #result.evidence,
      claims = #result.claims,
      github_profiles = #(config.github_profiles or {}),
      vacancy_id = result.vacancy_map and result.vacancy_map.vacancy_id or nil,
      translated_claims = result.cv_draft and #result.cv_draft.claim_ids or nil,
      guard_results = result.guard_results and #result.guard_results or nil,
      provider = result.runtime.provider,
      model = result.runtime.model,
      out = config.out,
    }) .. "\n")
  elseif config.command == "parse-vacancy" then
    local runtime_cfg = require("core.config").default_runtime("parse_vacancy")
    local vacancy_map = pipeline.run_parse_vacancy(config, runtime_cfg)
    io.stdout:write(json.encode_pretty({
      command = "parse-vacancy",
      vacancy_id = vacancy_map.vacancy_id,
      title = vacancy_map.title,
      role_archetype = vacancy_map.role_archetype,
      diagnosis_quality = vacancy_map.diagnosis_quality,
      ritualization_score = vacancy_map.ritualization_score,
      out = config.out,
    }) .. "\n")
  elseif config.command == "translate" then
    local result = pipeline.run_truth(config)
    local vacancy_runtime = require("core.config").default_runtime("parse_vacancy")
    local translate_runtime = require("core.config").default_runtime("translate")
    local vacancy_map = pipeline.run_parse_vacancy(config, vacancy_runtime)
    local draft = pipeline.run_translate(config, result.claims, vacancy_map, translate_runtime)
    io.stdout:write(json.encode_pretty({
      command = "translate",
      claims = #result.claims,
      translated_claims = #draft.claim_ids,
      vacancy_id = vacancy_map.vacancy_id,
      provider = translate_runtime.provider,
      model = translate_runtime.model,
      out = config.out,
    }) .. "\n")
  elseif config.command == "guard" then
    local result = pipeline.run_truth(config)
    local vacancy_runtime = require("core.config").default_runtime("parse_vacancy")
    local translate_runtime = require("core.config").default_runtime("translate")
    local guard_runtime = require("core.config").default_runtime("guard")
    local vacancy_map = pipeline.run_parse_vacancy(config, vacancy_runtime)
    local draft = pipeline.run_translate(config, result.claims, vacancy_map, translate_runtime)
    local guard_results = pipeline.run_guard(config, result.claims, result.evidence, vacancy_map, draft, guard_runtime)
    io.stdout:write(json.encode_pretty({
      command = "guard",
      claims = #result.claims,
      translated_claims = #draft.claim_ids,
      guard_results = #guard_results,
      vacancy_id = vacancy_map.vacancy_id,
      provider = guard_runtime.provider,
      model = guard_runtime.model,
      out = config.out,
    }) .. "\n")
  else
    error("unsupported command for first cut: " .. config.command)
  end
end

return M
