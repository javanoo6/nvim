return {
  "kawre/leetcode.nvim",
  cmd = "Leet",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-treesitter/nvim-treesitter",
    "nvim-telescope/telescope.nvim",
    "MunifTanjim/nui.nvim",
    "nvim-tree/nvim-web-devicons",
  },
  config = function()
    local private = require("private")
    local cache_dir = vim.fn.stdpath("cache") .. "/leetcode"
    local cookie_file = cache_dir .. "/cookie"

    if vim.fn.filereadable(cookie_file) == 0 then
      vim.fn.mkdir(cache_dir, "p")
      local f = io.open(cookie_file, "w")
      if f then
        f:write("csrftoken=" .. private.leetcode.csrf .. "; LEETCODE_SESSION=" .. private.leetcode.session)
        f:close()
      end
    end

    require("leetcode").setup({
      lang = "java",
      storage = {
        home = vim.fn.expand("~/leetcode"),
      },
      picker = { provider = "telescope" },
    })

    local script = vim.fn.expand("~/.config/nvim/scripts/update-leetcode-cookies.sh")
    vim.api.nvim_create_user_command("LeetCookies", function()
      local result = vim.fn.system(script)
      if vim.v.shell_error ~= 0 then
        vim.notify(result, vim.log.levels.ERROR)
      else
        vim.notify("LeetCode cookies updated", vim.log.levels.INFO)
      end
    end, { desc = "Refresh LeetCode cookies from Firefox" })
  end,
  keys = {
    { "<leader>Ll", "<cmd>Leet<cr>",         desc = "LeetCode menu" },
    { "<leader>Lr", "<cmd>Leet run<cr>",     desc = "LeetCode run" },
    { "<leader>Ls", "<cmd>Leet submit<cr>",  desc = "LeetCode submit" },
    { "<leader>Ld", "<cmd>Leet daily<cr>",   desc = "LeetCode daily" },
    { "<leader>Ln", "<cmd>Leet random<cr>",  desc = "LeetCode random" },
    { "<leader>Lc", "<cmd>Leet console<cr>", desc = "LeetCode console" },
    { "<leader>Li", "<cmd>Leet info<cr>",    desc = "LeetCode info" },
    { "<leader>Lt", "<cmd>Leet tabs<cr>",                        desc = "LeetCode tabs" },
    { "<leader>Le", "<cmd>Leet list difficulty=easy<cr>",    desc = "LeetCode easy problems" },
    { "<leader>Lm", "<cmd>Leet list difficulty=medium<cr>",  desc = "LeetCode medium problems" },
    { "<leader>Lh", "<cmd>Leet list difficulty=hard<cr>",    desc = "LeetCode hard problems" },
    { "<leader>LU", "<cmd>LeetCookies<cr>",                  desc = "LeetCode update cookies" },
  },
}
