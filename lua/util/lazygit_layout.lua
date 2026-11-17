local M = {}
local installed = false

function M.setup()
  if installed then
    return
  end
  installed = true
  local jobstart = vim.fn.jobstart
  vim.fn.jobstart = function(command, opts)
    -- lazygit.nvim launches an argv list in the current terminal buffer.
    if type(command) ~= "table" or vim.fn.fnamemodify(command[1], ":t") ~= "lazygit" or not (opts and opts.term) then
      return jobstart(command, opts)
    end
    local buf = vim.api.nvim_get_current_buf()
    local text_input, tail = false, ""
    opts = vim.tbl_extend("force", {}, opts)
    local on_stdout = opts.on_stdout
    opts.on_stdout = function(job, data, event)
      -- LazyGit 0.58 shows the terminal cursor for editable fields and hides
      -- it for command views (pkg/gui/context.go). Keep partial CSI sequences
      -- across callbacks; the last visibility change in a redraw wins.
      local output = tail .. table.concat(data, "\n")
      for visibility in output:gmatch("\27%[%?25([hl])") do
        text_input = visibility == "h"
      end
      tail = output:sub(-5)
      if vim.api.nvim_buf_is_valid(buf) then
        vim.b[buf].lazygit_russian_text_input = text_input
      end
      if on_stdout then
        on_stdout(job, data, event)
      end
    end
    local job = jobstart(command, opts)
    if job > 0 then
      require("util.russian_layout").setup_terminal(buf, function()
        return not text_input
      end)
    end
    return job
  end
end

return M
