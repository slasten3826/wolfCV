local fs = require("core.fs")
local github = require("core.github")
local ids = require("core.ids")
local repository_schema = require("schemas.repository_index")
local artifact_schema = require("schemas.artifact_batch")

local M = {}

local CLASS_BY_PATH_HINT = {
  ["/tests/"] = "TEST",
  ["/test/"] = "TEST",
  ["/docs/"] = "DOCS",
  ["/research/"] = "RESEARCH",
  ["/protocol"] = "PROTOCOL",
  ["/spec"] = "SPEC",
  ["/manifest"] = "META",
}

local CODE_EXT = {
  lua = true,
  py = true,
  rs = true,
  c = true,
  h = true,
  cpp = true,
  hpp = true,
  zig = true,
  js = true,
  ts = true,
}

local CONFIG_EXT = {
 toml = true,
  json = true,
  yaml = true,
  yml = true,
  ini = true,
}

local function extension_of(path)
  local ext = path:match("%.([^.]+)$")
  return ext and ext:lower() or ""
end

local function language_of(path)
  local ext = extension_of(path)
  if ext == "md" then
    return "markdown"
  elseif ext == "txt" then
    return "text"
  elseif ext ~= "" then
    return ext
  end
  return "unknown"
end

local function classify(rel_path)
  local path_lc = "/" .. rel_path:lower()
  local ext = extension_of(rel_path)

  if path_lc:find("/legacy/") or path_lc:find("/vendor/") or path_lc:find("/target/") or path_lc:find("/build/") then
    return "META", "noise"
  end

  for hint, class_name in pairs(CLASS_BY_PATH_HINT) do
    if path_lc:find(hint, 1, true) then
      return class_name, "normal"
    end
  end

  if CODE_EXT[ext] then
    return "CODE", "normal"
  elseif CONFIG_EXT[ext] then
    return "CONFIG", "normal"
  elseif ext == "md" then
    if path_lc:find("readme", 1, true) then
      return "INDEX", "normal"
    end
    return "DOCS", "normal"
  elseif ext == "txt" then
    return "DOCS", "normal"
  end

  return "DOCS", "normal"
end

local function role_tags_for(class_name, rel_path)
  local tags = {}
  local path_lc = rel_path:lower()

  if class_name == "CODE" then
    tags[#tags + 1] = "implementation"
  elseif class_name == "SPEC" then
    tags[#tags + 1] = "specification"
  elseif class_name == "RESEARCH" then
    tags[#tags + 1] = "research"
  elseif class_name == "TEST" then
    tags[#tags + 1] = "verification"
  elseif class_name == "PROTOCOL" then
    tags[#tags + 1] = "protocol"
  elseif class_name == "CONFIG" then
    tags[#tags + 1] = "configuration"
  else
    tags[#tags + 1] = "documentation"
  end

  if path_lc:find("runtime", 1, true) then
    tags[#tags + 1] = "runtime"
  end
  if path_lc:find("render", 1, true) then
    tags[#tags + 1] = "rendering"
  end
  if path_lc:find("llm", 1, true) or path_lc:find("lora", 1, true) then
    tags[#tags + 1] = "llm"
  end
  if path_lc:find("prompt", 1, true) then
    tags[#tags + 1] = "prompting"
  end
  if path_lc:find("spec", 1, true) or path_lc:find("canon", 1, true) then
    tags[#tags + 1] = "formal_spec"
  end

  return tags
end

local function summary_for(repo_name, rel_path, class_name)
  return string.format("%s artifact from %s", class_name:lower(), repo_name .. "/" .. rel_path)
end

function M.run(config)
  if (not config.repos or #config.repos == 0) and (not config.github_profiles or #config.github_profiles == 0) then
    error("scan requires at least one repo via --repos or one profile via --github-profile")
  end

  local repositories = {}
  local artifacts = {}
  local sources = {}

  for _, repo_path in ipairs(config.repos) do
    sources[#sources + 1] = {
      source_type = "local",
      local_path = repo_path,
      remote_url = nil,
      repo_name = nil,
      owner = "unknown",
    }
  end

  local github_sources = github.resolve_profile_sources(config)
  for _, source in ipairs(github_sources) do
    sources[#sources + 1] = source
  end

  for _, source in ipairs(sources) do
    local repo_path = source.local_path
    if not fs.is_dir(repo_path) then
      error("repo path is not a directory: " .. repo_path)
    end

    local local_path = fs.abspath(repo_path)
    local repo_name = source.repo_name or local_path:match("([^/]+)$") or local_path
    local repo_id = ids.repo_id(repo_name)
    repositories[#repositories + 1] = {
      repo_id = repo_id,
      source_type = source.source_type,
      local_path = local_path,
      remote_url = source.remote_url,
      repo_name = repo_name,
      owner = source.owner,
      branch = fs.git_branch(local_path),
      commit_ref = fs.git_commit(local_path),
    }

    local files = fs.list_repo_files(local_path)
    for _, rel_path in ipairs(files) do
      local class_name, visibility = classify(rel_path)
      artifacts[#artifacts + 1] = {
        artifact_id = ids.artifact_id(repo_name, rel_path),
        repo_id = repo_id,
        path = rel_path,
        kind = "file",
        language = language_of(rel_path),
        class = class_name,
        summary = summary_for(repo_name, rel_path, class_name),
        confidence = 0.55,
        role_tags = role_tags_for(class_name, rel_path),
        visibility = visibility,
      }
    end
  end

  local ok_repo, err_repo = repository_schema.validate(repositories)
  if not ok_repo then
    error(err_repo)
  end
  local ok_art, err_art = artifact_schema.validate(artifacts)
  if not ok_art then
    error(err_art)
  end

  return {
    repositories = repositories,
    artifacts = artifacts,
  }
end

function M.build_summary(result)
  local lines = {
    "WolfCV scan summary",
    "",
    "repositories: " .. tostring(#result.repositories),
    "artifacts: " .. tostring(#result.artifacts),
    "",
  }

  for _, repo in ipairs(result.repositories) do
    lines[#lines + 1] = string.format("- %s (%s @ %s)", repo.repo_name, repo.branch, repo.commit_ref)
  end

  return table.concat(lines, "\n") .. "\n"
end

return M
