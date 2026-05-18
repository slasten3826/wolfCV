local M = {}

local function count_decisions(items)
  local counts = {
    read_now = 0,
    read_if_needed = 0,
    skip = 0,
  }
  for _, item in ipairs(items or {}) do
    if counts[item.decision] ~= nil then
      counts[item.decision] = counts[item.decision] + 1
    end
  end
  return counts
end

local function lines_for_group(title, items, lookup)
  local lines = {
    "## " .. title,
    "",
  }

  if #items == 0 then
    lines[#lines + 1] = "- none"
    lines[#lines + 1] = ""
    return lines
  end

  for _, item in ipairs(items) do
    local batch = lookup[item.batch_id] or {}
    local repo_name = batch.repo_name or "unknown"
    local cluster_id = batch.cluster_id or "cluster"
    local count = batch.artifact_count or 0
    lines[#lines + 1] = string.format(
      "- `%s` | repo `%s` | cluster `%s` | artifacts `%d` | %s",
      item.batch_id,
      repo_name,
      cluster_id,
      count,
      item.reason or ""
    )
  end
  lines[#lines + 1] = ""
  return lines
end

function M.render(vacancy_map, batch_plan, selection)
  local counts = count_decisions(selection)
  local lookup = {}
  for _, batch in ipairs(batch_plan or {}) do
    lookup[batch.batch_id] = batch
  end

  local read_now = {}
  local read_if_needed = {}
  local skip = {}
  for _, item in ipairs(selection or {}) do
    if item.decision == "read_now" then
      read_now[#read_now + 1] = item
    elseif item.decision == "read_if_needed" then
      read_if_needed[#read_if_needed + 1] = item
    else
      skip[#skip + 1] = item
    end
  end

  local lines = {
    "# Batch Selection",
    "",
    "Vacancy: `" .. ((vacancy_map or {}).title or "Target role") .. "`",
    "",
    "Total planned batches: `" .. tostring(#(batch_plan or {})) .. "`",
    "Selected now: `" .. tostring(counts.read_now) .. "`",
    "Selected if needed: `" .. tostring(counts.read_if_needed) .. "`",
    "Skipped: `" .. tostring(counts.skip) .. "`",
    "",
  }

  local sections = {
    lines_for_group("Read Now", read_now, lookup),
    lines_for_group("Read If Needed", read_if_needed, lookup),
    lines_for_group("Skip", skip, lookup),
  }

  for _, section in ipairs(sections) do
    for _, line in ipairs(section) do
      lines[#lines + 1] = line
    end
  end

  return table.concat(lines, "\n") .. "\n"
end

return M
