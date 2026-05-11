local fs = require("core.fs")
local json = require("core.json")

local M = {}

function M.write_json(path, value)
  fs.write_file(path, json.encode_pretty(value) .. "\n")
end

function M.write_text(path, value)
  fs.write_file(path, value)
end

return M
