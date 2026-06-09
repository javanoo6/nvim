return {
  "kawre/leetcode.nvim",
  cmd = { "Leet", "LeetCookies", "LeetRoadmap" },
  dependencies = {
    "nvim-lua/plenary.nvim",
    "MunifTanjim/nui.nvim",
    "nvim-telescope/telescope.nvim",
  },
  config = function()
    -- Optional: Initialize cookie from private module if available
    local private_ok, private = pcall(require, "private")
    if private_ok and private.leetcode then
      local cookie_file = vim.fn.stdpath("cache") .. "/leetcode/cookie"
      if vim.fn.filereadable(cookie_file) == 0 then
        vim.fn.mkdir(vim.fn.stdpath("cache") .. "/leetcode", "p")
        local f = io.open(cookie_file, "w")
        if f then
          f:write("csrftoken=" .. private.leetcode.csrf .. "; LEETCODE_SESSION=" .. private.leetcode.session)
          f:close()
        end
      end
    end

    require("leetcode").setup({
      lang = "java",
      storage = {
        home = vim.fn.expand("~/leetcode"),
      },
      picker = { provider = "telescope" },
      plugins = { non_standalone = true },
    })

    local script = vim.fn.expand("~/.config/nvim/scripts/update-leetcode-cookies.sh")
    vim.api.nvim_create_user_command("LeetCookies", function()
      local result = vim.fn.system(script)
      if vim.v.shell_error ~= 0 then
        vim.notify("Failed: " .. vim.trim(result), vim.log.levels.ERROR)
        return
      end
      vim.notify("LeetCode cookies updated", vim.log.levels.INFO)
    end, { desc = "Refresh LeetCode cookies" })

    require("util.leetcode_roadmap").register_command()
  end,
  keys = {
    { "<leader>Ll", "<cmd>Leet<cr>", desc = "LeetCode menu" },
    { "<leader>Lr", "<cmd>Leet run<cr>", desc = "Run" },
    { "<leader>Ls", "<cmd>Leet submit<cr>", desc = "Submit" },
    { "<leader>Ld", "<cmd>Leet daily<cr>", desc = "Daily" },
    { "<leader>Ln", "<cmd>Leet random<cr>", desc = "Random" },
    { "<leader>Lc", "<cmd>Leet console<cr>", desc = "Console" },
    { "<leader>Li", "<cmd>Leet info<cr>", desc = "Info" },
    { "<leader>Lt", "<cmd>Leet tabs<cr>", desc = "Tabs" },
    { "<leader>Le", "<cmd>Leet list difficulty=easy<cr>", desc = "Easy" },
    { "<leader>Lm", "<cmd>Leet list difficulty=medium<cr>", desc = "Medium" },
    { "<leader>Lh", "<cmd>Leet list difficulty=hard<cr>", desc = "Hard" },
    { "<leader>LR", "<cmd>LeetRoadmap<cr>", desc = "DSA Roadmap" },
    { "<leader>LU", "<cmd>LeetCookies<cr>", desc = "Update cookies" },
  },
}
