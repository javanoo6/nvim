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

    -- Cookie refresh from Firefox
    local script = vim.fn.expand("~/.config/nvim/scripts/update-leetcode-cookies.sh")
    vim.api.nvim_create_user_command("LeetCookies", function()
      local result = vim.fn.system(script)
      if vim.v.shell_error ~= 0 then
        vim.notify("Failed: " .. vim.trim(result), vim.log.levels.ERROR)
        return
      end
      vim.notify("LeetCode cookies updated", vim.log.levels.INFO)
    end, { desc = "Refresh LeetCode cookies" })

    -- DSA Roadmap topics
    local roadmap_data = {
      { name = "Array", slug = "array" },
      { name = "Hash Table", slug = "hash-table" },
      { name = "Two Pointers", slug = "two-pointers" },
      { name = "Sliding Window", slug = "sliding-window" },
      { name = "Stack", slug = "stack" },
      { name = "Binary Search", slug = "binary-search" },
      { name = "Linked List", slug = "linked-list" },
      { name = "Tree", slug = "tree" },
      { name = "Binary Tree", slug = "binary-tree" },
      { name = "Trie", slug = "trie" },
      { name = "Heap/Priority Queue", slug = "heap-priority-queue" },
      { name = "Backtracking", slug = "backtracking" },
      { name = "Graph", slug = "graph" },
      { name = "DFS", slug = "depth-first-search" },
      { name = "BFS", slug = "breadth-first-search" },
      { name = "Union-Find", slug = "union-find" },
      { name = "Topological Sort", slug = "topological-sort" },
      { name = "Shortest Path", slug = "shortest-path" },
      { name = "Dynamic Programming", slug = "dynamic-programming" },
      { name = "Greedy", slug = "greedy" },
      { name = "Divide and Conquer", slug = "divide-and-conquer" },
      { name = "Bit Manipulation", slug = "bit-manipulation" },
      { name = "Math", slug = "math" },
      { name = "String", slug = "string" },
      { name = "Sorting", slug = "sorting" },
      { name = "Matrix", slug = "matrix" },
      { name = "Prefix Sum", slug = "prefix-sum" },
      { name = "Segment Tree", slug = "segment-tree" },
    }

    local function pick_by_roadmap()
      -- Step 1: Select topic
      vim.ui.select(roadmap_data, {
        prompt = "Select topic:",
        format_item = function(t)
          return t.name
        end,
      }, function(selected_topic)
        if not selected_topic then
          return
        end

        -- Step 2: Select difficulty
        vim.ui.select({ "All", "Easy", "Medium", "Hard" }, {
          prompt = "Select difficulty:",
        }, function(selected_diff)
          if not selected_diff then
            return
          end

          vim.notify("Fetching " .. selected_topic.name .. " problems...", vim.log.levels.INFO)

          -- Step 3: Query LeetCode API (cache has no topic_tags)
          local gql = [[
            query questionList($categorySlug: String, $limit: Int, $skip: Int, $filters: QuestionListFilterInput) {
              questionList(categorySlug: $categorySlug limit: $limit skip: $skip filters: $filters) {
                questions: data {
                  acRate
                  difficulty
                  frontendQuestionId: questionFrontendId
                  isPaidOnly
                  status
                  title
                  titleSlug
                }
              }
            }
          ]]

          local filters = { tags = { selected_topic.slug } }
          if selected_diff ~= "All" then
            filters.difficulty = selected_diff:upper()
          end

          require("leetcode.api.utils").query(gql, {
            categorySlug = "",
            skip = 0,
            limit = 3000,
            filters = filters,
          }, {
            callback = function(res, err)
              if err then
                vim.notify("LeetRoadmap failed: " .. (err.msg or "unknown error"), vim.log.levels.ERROR)
                return
              end

              local ql = res and res.data and res.data.questionList
              local questions = ql and ql.questions or {}

              if #questions == 0 then
                vim.notify(
                  "No problems found for " .. selected_topic.name .. " (" .. selected_diff .. ")",
                  vim.log.levels.WARN
                )
                return
              end

              local domain = require("leetcode.config").domain
              local problems = vim.tbl_map(function(q)
                return {
                  id = 0,
                  frontend_id = tostring(q.frontendQuestionId),
                  title = q.title,
                  title_cn = "",
                  title_slug = q.titleSlug,
                  link = ("https://leetcode.%s/problems/%s/"):format(domain, q.titleSlug),
                  paid_only = q.isPaidOnly == true,
                  ac_rate = q.acRate or 0,
                  difficulty = q.difficulty,
                  status = (q.status == vim.NIL or not q.status) and "todo" or q.status,
                  topic_tags = {},
                }
              end, questions)

              vim.notify(
                "Found "
                  .. #problems
                  .. " problems for "
                  .. selected_topic.name
                  .. (selected_diff ~= "All" and (" (" .. selected_diff .. ")") or ""),
                vim.log.levels.INFO
              )

              -- Step 4: Open filtered list in picker
              require("leetcode.picker").question(problems, {})
            end,
          })
        end)
      end)
    end

    vim.api.nvim_create_user_command("LeetRoadmap", pick_by_roadmap, {
      desc = "Browse LeetCode DSA roadmap",
    })
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
