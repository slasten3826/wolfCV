local M = {}

local function push(lines, value)
  lines[#lines + 1] = value
end

local function count_guard_status(results)
  local counts = {
    SUPPORTED = 0,
    PARTIALLY_SUPPORTED = 0,
    RITUAL_TRANSLATION = 0,
    UNSUPPORTED = 0,
    FORBIDDEN = 0,
    review_required = 0,
  }

  for _, item in ipairs(results or {}) do
    if counts[item.status] ~= nil then
      counts[item.status] = counts[item.status] + 1
    end
    if item.review_required then
      counts.review_required = counts.review_required + 1
    end
  end

  return counts
end

local function translated_bullet_count(draft, guard_results)
  local allowed = {
    SUPPORTED = true,
    PARTIALLY_SUPPORTED = true,
    RITUAL_TRANSLATION = true,
  }
  local guard_map = {}
  for _, item in ipairs(guard_results or {}) do
    guard_map[item.claim_id] = item
  end

  local total = 0
  for _, bullet in ipairs((draft or {}).project_bullets or {}) do
    local claim_id = bullet.claim_ids and bullet.claim_ids[1] or nil
    local guard = claim_id and guard_map[claim_id] or nil
    if guard and allowed[guard.status] and not guard.review_required then
      total = total + 1
    end
  end
  return total
end

local function overall_state(vacancy_map, draft, guard_results)
  local quality = vacancy_map and vacancy_map.diagnosis_quality or "unknown"
  local guard_counts = count_guard_status(guard_results)
  local bullet_count = translated_bullet_count(draft, guard_results)

  if quality == "degraded" then
    return "degraded"
  end
  if guard_counts.review_required > 0 or bullet_count == 0 then
    return "partial"
  end
  if quality == "partial" then
    return "partial"
  end
  return "solid"
end

local function recommendation(vacancy_map, draft, guard_results)
  local quality = vacancy_map and vacancy_map.diagnosis_quality or "unknown"
  local guard_counts = count_guard_status(guard_results)
  local bullet_count = translated_bullet_count(draft, guard_results)

  if quality == "degraded" then
    return "Read `vacancy_diagnosis.md` first. The target reading is weak, so do not trust `wolfcv.md` as a serious final surface yet."
  end
  if bullet_count == 0 then
    return "Read `machinecv.md` and `evidence_guard_report.md`. The truth layer exists, but no safe translated highlights survived yet."
  end
  if guard_counts.review_required > 0 then
    return "Read `evidence_guard_report.md` after `wolfcv.md`. Some translated claims still require human review."
  end
  return "Read the four main surfaces in order. This run is strong enough for normal inspection."
end

function M.render(result)
  local vacancy_map = result.vacancy_map or {}
  local draft = result.cv_draft or {}
  local guard_results = result.guard_results or {}
  local guard_counts = count_guard_status(guard_results)
  local bullet_count = translated_bullet_count(draft, guard_results)
  local state = overall_state(vacancy_map, draft, guard_results)

  local lines = {}
  push(lines, "# WolfCV Start Here")
  push(lines, "")
  push(lines, "Overall state: " .. state)
  push(lines, "Vacancy diagnosis quality: " .. tostring(vacancy_map.diagnosis_quality or "unknown"))
  push(lines, "Target role: " .. tostring(draft.role_title or vacancy_map.title or "Target role"))
  push(lines, "")
  push(lines, "## Read First")
  push(lines, "")
  push(lines, "1. `vacancy_diagnosis.md`")
  push(lines, "2. `machinecv.md`")
  push(lines, "3. `hhcv.md`")
  push(lines, "4. `wolfcv.md`")
  push(lines, "5. `evidence_guard_report.md`")
  push(lines, "")
  push(lines, "## What This Run Produced")
  push(lines, "")
  push(lines, "- evidence count: " .. tostring(#(result.evidence or {})))
  push(lines, "- claim count: " .. tostring(#(result.claims or {})))
  push(lines, "- draft claim count: " .. tostring(#(draft.claim_ids or {})))
  push(lines, "- safe translated highlights: " .. tostring(bullet_count))
  push(lines, "")
  push(lines, "## Guard Summary")
  push(lines, "")
  push(lines, "- supported: " .. tostring(guard_counts.SUPPORTED))
  push(lines, "- partially_supported: " .. tostring(guard_counts.PARTIALLY_SUPPORTED))
  push(lines, "- ritual_translation: " .. tostring(guard_counts.RITUAL_TRANSLATION))
  push(lines, "- unsupported: " .. tostring(guard_counts.UNSUPPORTED))
  push(lines, "- forbidden: " .. tostring(guard_counts.FORBIDDEN))
  push(lines, "- review_required: " .. tostring(guard_counts.review_required))
  push(lines, "")
  push(lines, "## Recommendation")
  push(lines, "")
  push(lines, recommendation(vacancy_map, draft, guard_results))
  push(lines, "")
  push(lines, "## Important")
  push(lines, "")
  push(lines, "- `solid` does not mean perfect. It means the current run is coherent enough for normal reading.")
  push(lines, "- `partial` means the run is useful, but some important surfaces are weak or constrained.")
  push(lines, "- `degraded` means the target reading is weak enough that the rest should be treated carefully.")
  push(lines, "")

  return table.concat(lines, "\n") .. "\n"
end

return M
