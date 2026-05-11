local cli = require("cli.app")

local ok, err = pcall(cli.run, arg)
if not ok then
  io.stderr:write("wolfcv: " .. tostring(err) .. "\n")
  os.exit(1)
end
