local M = {}

local function notify(msg, level)
  vim.notify(msg, level or vim.log.levels.INFO, { title = "java debug" })
end

local function get_java_launch_configs()
  local dap = require("dap")
  local configs = dap.configurations.java or {}
  local seen = {}
  local result = {}

  for _, config in ipairs(configs) do
    if config.request == "launch" and config.name and not seen[config.name] then
      seen[config.name] = true
      result[#result + 1] = config
    end
  end

  return result
end

local function ensure_java_dap_configured()
  local dap = require("dap")
  local ok, java_dap = pcall(require, "java-dap")
  if not ok then
    notify("java-dap is unavailable; open a Java buffer and wait for jdtls", vim.log.levels.ERROR)
    return false
  end

  if #(dap.configurations.java or {}) == 0 then
    java_dap.config_dap()
  end

  return true
end

function M.debug_main()
  if not ensure_java_dap_configured() then
    return
  end

  local dap = require("dap")
  local configs = get_java_launch_configs()

  if #configs == 0 then
    notify("No Java launch configs found; open a Java main class project and wait for jdtls", vim.log.levels.WARN)
    return
  end

  if #configs == 1 then
    dap.run(vim.deepcopy(configs[1]))
    return
  end

  vim.ui.select(configs, {
    prompt = "Debug Java main",
    format_item = function(config)
      return config.name
    end,
  }, function(choice)
    if choice then
      dap.run(vim.deepcopy(choice))
    end
  end)
end

function M.attach_remote()
  if not ensure_java_dap_configured() then
    return
  end

  local host = vim.fn.input("JDWP host: ", "127.0.0.1")
  if host == nil or host == "" then
    return
  end

  local port_input = vim.fn.input("JDWP port: ", "5005")
  if port_input == nil or port_input == "" then
    return
  end

  local port = tonumber(port_input)
  if not port then
    notify("JDWP port must be a number", vim.log.levels.ERROR)
    return
  end

  require("dap").run({
    type = "java",
    request = "attach",
    name = string.format("Attach JVM (%s:%d)", host, port),
    hostName = host,
    port = port,
  })
end

return M
