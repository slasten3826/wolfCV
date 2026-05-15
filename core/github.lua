local fs = require("core.fs")
local json = require("core.json")

local M = {}

local function run_capture(command)
  local pipe = assert(io.popen(command))
  local output = pipe:read("*a") or ""
  local ok, _, code = pipe:close()
  if ok == nil and code ~= 0 then
    error("command failed: " .. command)
  end
  return output
end

local function normalize_profile(value)
  value = tostring(value or "")
  value = value:gsub("^https?://github%.com/", "")
  value = value:gsub("/+$", "")
  value = value:match("^([^/]+)") or value
  if value == "" then
    error("empty github profile")
  end
  return value
end

local function repo_allowed(repo, include, exclude)
  local haystack = (repo.name .. " " .. (repo.description or "")):lower()

  if include and #include > 0 then
    local matched = false
    for _, token in ipairs(include) do
      if haystack:find(token:lower(), 1, true) then
        matched = true
        break
      end
    end
    if not matched then
      return false
    end
  end

  if exclude and #exclude > 0 then
    for _, token in ipairs(exclude) do
      if haystack:find(token:lower(), 1, true) then
        return false
      end
    end
  end

  return true
end

local function fetch_profile_repos(profile)
  local repos = {}
  local page = 1

  while true do
    local url = string.format(
      "https://api.github.com/users/%s/repos?per_page=100&page=%d&sort=updated",
      profile,
      page
    )
    local command = "curl -fsSL " .. fs.shell_quote(url)
    local body = run_capture(command)
    local decoded = json.decode(body)
    if type(decoded) ~= "table" then
      error("github profile repo listing must decode to an array")
    end
    if #decoded == 0 then
      break
    end

    for _, repo in ipairs(decoded) do
      repos[#repos + 1] = repo
    end

    if #decoded < 100 then
      break
    end
    page = page + 1
  end

  return repos
end

local function ensure_repo_clone(repo, target_dir, refresh)
  if fs.is_dir(target_dir) then
    if refresh then
      local command = string.format(
        "git -C %s pull --ff-only --quiet",
        fs.shell_quote(target_dir)
      )
      os.execute(command)
    end
    return target_dir
  end

  local command = string.format(
    "git clone --depth 1 %s %s >/dev/null 2>&1",
    fs.shell_quote(repo.clone_url),
    fs.shell_quote(target_dir)
  )
  local ok = os.execute(command)
  if not (ok == true or ok == 0) then
    error("failed to clone github repo: " .. tostring(repo.clone_url))
  end

  return target_dir
end

function M.resolve_profile_sources(config)
  local resolved = {}

  for _, raw_profile in ipairs(config.github_profiles or {}) do
    local profile = normalize_profile(raw_profile)
    local repos = fetch_profile_repos(profile)
    table.sort(repos, function(a, b)
      return tostring(a.name or "") < tostring(b.name or "")
    end)

    for _, repo in ipairs(repos) do
      if repo_allowed(repo, config.include, config.exclude) then
        local local_path = fs.join(config.github_cache, profile, repo.name)
        ensure_repo_clone(repo, local_path, config.refresh_github)
        resolved[#resolved + 1] = {
          source_type = "github",
          local_path = local_path,
          remote_url = repo.clone_url,
          repo_name = repo.name,
          owner = ((repo.owner or {}).login) or profile,
        }
      end
    end
  end

  return resolved
end

return M
