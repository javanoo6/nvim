local M = {}

local telescope_loaded = false

local function load_yanky()
  pcall(require("lazy").load, { plugins = { "yanky.nvim" } })
end

function M.delete_selection(prompt_bufnr)
  local picker = require("telescope.actions.state").get_current_picker(prompt_bufnr)
  picker:delete_selection(function(entry)
    local index = entry.value.history_index
    require("yanky.history").delete(index)

    -- Yanky snapshots storage indexes when opening the picker. Every deletion
    -- shifts the remaining indexes, including entries hidden by the search.
    for _, remaining in ipairs(picker.finder.results) do
      if remaining.value.history_index > index then
        remaining.value.history_index = remaining.value.history_index - 1
      end
    end
  end)
end

function M.open_history()
  load_yanky()

  local ok_telescope, telescope = pcall(require, "telescope")
  if not ok_telescope then
    vim.notify("Telescope unavailable; opening Yanky ring history", vim.log.levels.WARN)
    vim.cmd.YankyRingHistory()
    return
  end

  if not telescope_loaded then
    local ok = pcall(telescope.load_extension, "yank_history")
    if not ok then
      vim.notify("Yanky Telescope picker unavailable; opening ring history", vim.log.levels.WARN)
      vim.cmd.YankyRingHistory()
      return
    end
    telescope_loaded = true
  end

  telescope.extensions.yank_history.yank_history()
end

function M.open_ring_history()
  load_yanky()
  vim.cmd.YankyRingHistory()
end

return M
