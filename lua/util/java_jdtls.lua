local M = {}

function M.patch_jdtls_cmd()
  local jdtls_cmd = require("java-core.ls.servers.jdtls.cmd")
  local orig_get_jvm_args = jdtls_cmd.get_jvm_args

  jdtls_cmd.get_jvm_args = function(cfg)
    local list = orig_get_jvm_args(cfg)
    for i, v in ipairs(list) do
      if v == "-Xms1G" then
        list[i] = "-Xms2G"
        break
      end
    end
    list:push("-Xmx8G")
    return list
  end
end

return M
