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

    local tag_query = [[
      query ($categorySlug: String, $limit: Int, $skip: Int, $filters: QuestionListFilterInput) {
        questionList(categorySlug: $categorySlug limit: $limit skip: $skip filters: $filters) {
          total: totalNum
          questions: data {
            acRate
            difficulty
            frontendQuestionId: questionFrontendId
            paidOnly: isPaidOnly
            status
            title
            titleSlug
            topicTags { name slug }
          }
        }
      }
    ]]

    local difficulties = { "All", "Easy", "Medium", "Hard" }

    local function pick_by_tag(slug, difficulty)
      local lc_config = require("leetcode.config")
      if not lc_config.storage.cache then
        lc_config.setup()
      end
      for _, mod in ipairs({
        "leetcode.cache.cookie",
        "leetcode.api.headers",
        "leetcode.api.utils",
        "leetcode.cache.problemlist",
      }) do
        if package.loaded[mod] == false then package.loaded[mod] = nil end
      end

      local filters = { tags = { slug } }
      if difficulty and difficulty ~= "All" then
        filters.difficulty = difficulty:upper()
      end

      vim.notify("Fetching " .. slug .. (difficulty and difficulty ~= "All" and " (" .. difficulty .. ")" or "") .. "…", vim.log.levels.INFO)
      local utils = require("leetcode.api.utils")
      utils.query(tag_query, { categorySlug = "", limit = 3000, skip = 0, filters = filters }, {
        callback = function(res, err)
          if err then
            vim.notify("Failed: " .. err.msg, vim.log.levels.ERROR)
            return
          end
          local domain = lc_config.domain or "com"
          local items = vim.tbl_map(function(q)
            return {
              id = 0,
              frontend_id = q.frontendQuestionId,
              title = q.title,
              title_cn = "",
              title_slug = q.titleSlug,
              link = ("https://leetcode.%s/problems/%s/"):format(domain, q.titleSlug),
              paid_only = q.paidOnly,
              ac_rate = q.acRate,
              difficulty = q.difficulty,
              status = (q.status == vim.NIL or q.status == nil) and "todo" or q.status,
              topic_tags = q.topicTags or {},
            }
          end, res.data.questionList.questions)
          require("leetcode.picker").question(items, {})
        end,
      })
    end

    local all_tags = {
      { name = "Array",                  slug = "array" },
      { name = "Backtracking",           slug = "backtracking" },
      { name = "Binary Indexed Tree",    slug = "binary-indexed-tree" },
      { name = "Binary Search",          slug = "binary-search" },
      { name = "Binary Search Tree",     slug = "binary-search-tree" },
      { name = "Binary Tree",            slug = "binary-tree" },
      { name = "Bit Manipulation",       slug = "bit-manipulation" },
      { name = "Breadth-First Search",   slug = "breadth-first-search" },
      { name = "Combinatorics",          slug = "combinatorics" },
      { name = "Concurrency",            slug = "concurrency" },
      { name = "Database",               slug = "database" },
      { name = "Depth-First Search",     slug = "depth-first-search" },
      { name = "Design",                 slug = "design" },
      { name = "Divide and Conquer",     slug = "divide-and-conquer" },
      { name = "Dynamic Programming",    slug = "dynamic-programming" },
      { name = "Game Theory",            slug = "game-theory" },
      { name = "Geometry",               slug = "geometry" },
      { name = "Graph",                  slug = "graph" },
      { name = "Greedy",                 slug = "greedy" },
      { name = "Hash Table",             slug = "hash-table" },
      { name = "Heap / Priority Queue",  slug = "heap-priority-queue" },
      { name = "Linked List",            slug = "linked-list" },
      { name = "Math",                   slug = "math" },
      { name = "Matrix",                 slug = "matrix" },
      { name = "Monotonic Stack",        slug = "monotonic-stack" },
      { name = "Number Theory",          slug = "number-theory" },
      { name = "Prefix Sum",             slug = "prefix-sum" },
      { name = "Queue",                  slug = "queue" },
      { name = "Recursion",              slug = "recursion" },
      { name = "Segment Tree",           slug = "segment-tree" },
      { name = "Shortest Path",          slug = "shortest-path" },
      { name = "Simulation",             slug = "simulation" },
      { name = "Sliding Window",         slug = "sliding-window" },
      { name = "Sorting",                slug = "sorting" },
      { name = "Stack",                  slug = "stack" },
      { name = "String",                 slug = "string" },
      { name = "String Matching",        slug = "string-matching" },
      { name = "Topological Sort",       slug = "topological-sort" },
      { name = "Tree",                   slug = "tree" },
      { name = "Trie",                   slug = "trie" },
      { name = "Two Pointers",           slug = "two-pointers" },
      { name = "Union-Find",             slug = "union-find" },
    }

    local function ask_difficulty(cb)
      vim.ui.select(difficulties, { prompt = "Difficulty:" }, function(choice)
        if choice then cb(choice) end
      end)
    end

    vim.api.nvim_create_user_command("LeetTopic", function()
      vim.ui.select(all_tags, {
        prompt = "Select topic:",
        format_item = function(t) return t.name end,
      }, function(selected)
        if not selected then return end
        ask_difficulty(function(diff) pick_by_tag(selected.slug, diff) end)
      end)
    end, { desc = "Browse LeetCode problems by topic" })

    local roadmap = {
      { name = "Array",                slug = "array" },
      { name = "Hash Table",           slug = "hash-table" },
      { name = "Two Pointers",         slug = "two-pointers" },
      { name = "Sliding Window",       slug = "sliding-window" },
      { name = "Stack",                slug = "stack" },
      { name = "Binary Search",        slug = "binary-search" },
      { name = "Linked List",          slug = "linked-list" },
      { name = "Tree",                 slug = "tree" },
      { name = "Binary Tree",          slug = "binary-tree" },
      { name = "Binary Search Tree",   slug = "binary-search-tree" },
      { name = "Trie",                 slug = "trie" },
      { name = "Heap / Priority Queue", slug = "heap-priority-queue" },
      { name = "Backtracking",         slug = "backtracking" },
      { name = "Graph",                slug = "graph" },
      { name = "Depth-First Search",   slug = "depth-first-search" },
      { name = "Breadth-First Search", slug = "breadth-first-search" },
      { name = "Union-Find",           slug = "union-find" },
      { name = "Topological Sort",     slug = "topological-sort" },
      { name = "Shortest Path",        slug = "shortest-path" },
      { name = "Dynamic Programming",  slug = "dynamic-programming" },
      { name = "Greedy",               slug = "greedy" },
      { name = "Divide and Conquer",   slug = "divide-and-conquer" },
      { name = "Bit Manipulation",     slug = "bit-manipulation" },
      { name = "Math",                 slug = "math" },
      { name = "Number Theory",        slug = "number-theory" },
      { name = "String",               slug = "string" },
      { name = "String Matching",      slug = "string-matching" },
      { name = "Sorting",              slug = "sorting" },
      { name = "Simulation",           slug = "simulation" },
      { name = "Matrix",               slug = "matrix" },
      { name = "Prefix Sum",           slug = "prefix-sum" },
      { name = "Monotonic Stack",      slug = "monotonic-stack" },
      { name = "Segment Tree",         slug = "segment-tree" },
      { name = "Binary Indexed Tree",  slug = "binary-indexed-tree" },
      { name = "Design",               slug = "design" },
    }

    vim.api.nvim_create_user_command("LeetRoadmap", function()
      local indexed = vim.tbl_map(function(t)
        return vim.tbl_extend("force", t, { idx = vim.tbl_contains(roadmap, t) })
      end, roadmap)
      for i, t in ipairs(roadmap) do t._idx = i end
      vim.ui.select(roadmap, {
        prompt = "DSA Roadmap:",
        format_item = function(t) return ("%02d. %s"):format(t._idx, t.name) end,
      }, function(selected)
        if not selected then return end
        ask_difficulty(function(diff) pick_by_tag(selected.slug, diff) end)
      end)
    end, { desc = "Browse LeetCode problems by DSA roadmap" })
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
    { "<leader>Lp", "<cmd>LeetTopic<cr>",                    desc = "LeetCode pick topic" },
    { "<leader>LR", "<cmd>LeetRoadmap<cr>",                 desc = "LeetCode DSA roadmap" },
    { "<leader>LU", "<cmd>LeetCookies<cr>",                 desc = "LeetCode update cookies" },
  },
}
