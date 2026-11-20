local M = {}

function M.setup()
  require("util.input").setup_lazygit()
  vim.g.lazygit_floating_window_scaling_factor = 1
  vim.g.lazygit_floating_window_border_chars = "none"
  local nvim_config = vim.fn.stdpath("config")
  vim.env.NVIM_LAZYGIT_OPEN_HELPER = nvim_config .. "/scripts/lazygit-open-in-nvim.sh"
  vim.env.NVIM_LAZYGIT_UNSTASH_HELPER = nvim_config .. "/scripts/lazygit-unstash.sh"

  local paths = {}
  if vim.fn.executable("lazygit") == 1 then
    local result = vim.system({ "lazygit", "--print-config-dir" }, { text = true }):wait()
    local dir = result.code == 0 and vim.trim(result.stdout or "") or ""
    if dir ~= "" then
      local path = dir .. "/config.yml"
      if vim.fn.filereadable(path) == 1 then
        paths[#paths + 1] = path
      end
    end
  end
  paths[#paths + 1] = nvim_config .. "/lazygit/config.yml"
  vim.g.lazygit_use_custom_config_file_path = 1
  vim.g.lazygit_config_file_path = paths
end

return M
