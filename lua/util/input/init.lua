local M = {}
local normalizer = require("util.input.normalizer").new(require("util.input.layouts").russian)

function M.setup()
  require("util.input.adapters.neovim").setup(normalizer)
end

function M.setup_which_key()
  require("util.input.adapters.which_key").setup(normalizer)
end

function M.setup_lazygit()
  require("util.input.adapters.lazygit").setup(normalizer)
end

return M
