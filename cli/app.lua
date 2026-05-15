local parser = require("cli.parse")
local json = require("core.json")
local pipeline = require("core.pipeline")

local M = {}

local function usage()
  return table.concat({
    "usage:",
    "  lua main.lua scan --repos ./repo1 ./repo2 --out ./wolfcv-out",
    "  lua main.lua classify --repos ./repo1 ./repo2 --out ./wolfcv-out",
    "  lua main.lua truth --repos ./repo1 ./repo2 --out ./wolfcv-out",
    "  lua main.lua parse-vacancy --target ./vacancy.txt --out ./wolfcv-out",
    "  lua main.lua translate --repos ./repo1 ./repo2 --target ./vacancy.txt --out ./wolfcv-out",
    "  lua main.lua guard --repos ./repo1 ./repo2 --target ./vacancy.txt --out ./wolfcv-out",
    "  lua main.lua run --repos ./repo1 ./repo2 --target ./vacancy.txt --out ./wolfcv-out",
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
      vacancy_id = result.vacancy_map and result.vacancy_map.vacancy_id or nil,
      translated_claims = result.cv_draft and #result.cv_draft.claim_ids or nil,
      guard_results = result.guard_results and #result.guard_results or nil,
      provider = result.runtime.provider,
      model = result.runtime.model,
      out = config.out,
    }) .. "\n")
  elseif config.command == "parse-vacancy" then
    local runtime_cfg = require("core.config").default_runtime()
    local vacancy_map = pipeline.run_parse_vacancy(config, runtime_cfg)
    io.stdout:write(json.encode_pretty({
      command = "parse-vacancy",
      vacancy_id = vacancy_map.vacancy_id,
      title = vacancy_map.title,
      out = config.out,
    }) .. "\n")
  elseif config.command == "translate" then
    local result = pipeline.run_truth(config)
    local vacancy_map = pipeline.run_parse_vacancy(config, result.runtime)
    local draft = pipeline.run_translate(config, result.claims, vacancy_map, result.runtime)
    io.stdout:write(json.encode_pretty({
      command = "translate",
      claims = #result.claims,
      translated_claims = #draft.claim_ids,
      vacancy_id = vacancy_map.vacancy_id,
      provider = result.runtime.provider,
      model = result.runtime.model,
      out = config.out,
    }) .. "\n")
  elseif config.command == "guard" then
    local result = pipeline.run_truth(config)
    local vacancy_map = pipeline.run_parse_vacancy(config, result.runtime)
    local draft = pipeline.run_translate(config, result.claims, vacancy_map, result.runtime)
    local guard_results = pipeline.run_guard(config, result.claims, result.evidence, vacancy_map, draft, result.runtime)
    io.stdout:write(json.encode_pretty({
      command = "guard",
      claims = #result.claims,
      translated_claims = #draft.claim_ids,
      guard_results = #guard_results,
      vacancy_id = vacancy_map.vacancy_id,
      provider = result.runtime.provider,
      model = result.runtime.model,
      out = config.out,
    }) .. "\n")
  else
    error("unsupported command for first cut: " .. config.command)
  end
end

return M
