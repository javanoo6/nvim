local M = {}

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

local function ensure_leetcode_ready()
  local lc_config = require("leetcode.config")
  if lc_config.storage and lc_config.storage.cache and lc_config.storage.home then
    return true
  end

  local ok, err = pcall(lc_config.setup)
  if not ok then
    vim.notify("LeetCode init failed: " .. tostring(err), vim.log.levels.ERROR)
    return false
  end

  return true
end

local function query_questions(topic, difficulty)
  vim.notify("Fetching " .. topic.name .. " problems...", vim.log.levels.INFO)

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

  local filters = { tags = { topic.slug } }
  if difficulty ~= "All" then
    filters.difficulty = difficulty:upper()
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
        vim.notify("No problems found for " .. topic.name .. " (" .. difficulty .. ")", vim.log.levels.WARN)
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
        "Found " .. #problems .. " problems for " .. topic.name .. (difficulty ~= "All" and (" (" .. difficulty .. ")") or ""),
        vim.log.levels.INFO
      )

      require("leetcode.picker").question(problems, {})
    end,
  })
end

function M.pick_by_roadmap()
  if not ensure_leetcode_ready() then
    return
  end

  vim.ui.select(roadmap_data, {
    prompt = "Select topic:",
    format_item = function(topic)
      return topic.name
    end,
  }, function(topic)
    if not topic then
      return
    end

    vim.ui.select({ "All", "Easy", "Medium", "Hard" }, {
      prompt = "Select difficulty:",
    }, function(difficulty)
      if not difficulty then
        return
      end

      query_questions(topic, difficulty)
    end)
  end)
end

function M.register_command()
  vim.api.nvim_create_user_command("LeetRoadmap", M.pick_by_roadmap, {
    desc = "Browse LeetCode DSA roadmap",
  })
end

return M
