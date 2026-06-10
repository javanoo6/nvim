local scratch_filetypes = { "lua", "js", "py", "sh", "java" }
local util = require("util")
-- Toggle these two settings by commenting/uncommenting a single line.
local global_scratch_dir = vim.fn.stdpath("state") .. "/scratch"
-- local global_scratch_dir = vim.fn.stdpath("data") .. "/scratch"
local java_scratch_in_project = true
-- local java_scratch_in_project = false

local java_build_markers = {
  "pom.xml",
  "build.gradle",
  "build.gradle.kts",
  "settings.gradle",
  "settings.gradle.kts",
}

local function current_path()
  local name = vim.api.nvim_buf_get_name(0)
  if name ~= "" then
    return name
  end
  return util.get_cwd()
end

local function find_java_project_root()
  local path = current_path()
  -- For Java scratch we want Maven/Gradle project context, not just generic
  -- editor root detection. JDTLS resolves dependencies from build-aware roots.
  local root = vim.fs.find(java_build_markers, {
    path = vim.fn.isdirectory(path) == 1 and path or vim.fs.dirname(path),
    upward = true,
  })[1]

  return root and vim.fs.dirname(root) or nil
end

local function java_scratch_path()
  if not java_scratch_in_project then
    return global_scratch_dir .. "/Scratch.java"
  end

  local root = find_java_project_root()
  if not root then
    return global_scratch_dir .. "/Scratch.java"
  end

  local src_test = root .. "/src/test/java"
  local src_main = root .. "/src/main/java"

  -- Prefer test sources so the scratch file is less likely to interfere with
  -- application code, but still lives inside the real project classpath.
  if vim.fn.isdirectory(src_test) == 1 then
    return src_test .. "/Scratch.java"
  end
  if vim.fn.isdirectory(src_main) == 1 then
    return src_main .. "/Scratch.java"
  end

  -- Fall back to a conventional test source root and create it on demand.
  return src_test .. "/Scratch.java"
end

local function open_java_project_scratch()
  local path = java_scratch_path()
  if not path then
    return false
  end

  local is_new = vim.fn.filereadable(path) ~= 1
  vim.fn.mkdir(vim.fn.fnamemodify(path, ":h"), "p")
  vim.cmd("edit " .. vim.fn.fnameescape(path))

  if is_new then
    -- Mirror the IntelliJ-style Java scratch shape so the file is immediately
    -- runnable and has a predictable edit point inside main().
    vim.api.nvim_buf_set_lines(0, 0, -1, false, {
      "class Scratch {",
      "    public static void main(String[] args) {",
      "        ",
      "    }",
      "}",
    })
    vim.api.nvim_win_set_cursor(0, { 3, 8 })
  end

  return true
end

local function scratch_by_type(ft)
  -- Only Java needs a project-local scratch to inherit dependencies.
  -- Other filetypes should keep scratch.nvim's normal global storage.
  if ft == "java" and open_java_project_scratch() then
    return
  end

  require("scratch").scratchByType(ft)
end

local function select_scratch_type()
  vim.ui.select(scratch_filetypes, {
    prompt = "Select filetype",
    format_item = function(item)
      return item
    end,
  }, function(choice)
    if choice then
      scratch_by_type(choice)
    end
  end)
end

local function open_scratch()
  -- In Java projects, reopening the project-local Scratch.java is usually more
  -- useful than jumping to the global scratch list because it preserves JDTLS
  -- project context. Outside Java projects we fall back to scratch.nvim.
  if open_java_project_scratch() then
    return
  end

  require("scratch").scratchOpen()
end

local function scratch_info()
  local ft = vim.bo.filetype ~= "" and vim.bo.filetype or "<none>"
  local java_root = find_java_project_root()
  local lines = {
    "Current filetype: " .. ft,
    "Global scratch dir: " .. global_scratch_dir,
    "Java project scratch: " .. (java_scratch_in_project and "enabled" or "disabled"),
    "Java project root: " .. (java_root or "<not found>"),
    "Java scratch path: " .. java_scratch_path(),
  }

  if ft ~= "java" then
    lines[#lines + 1] = "Non-Java scratches use scratch.nvim storage under the global scratch dir."
  end

  vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO, { title = "ScratchInfo" })
end

return {
  {
    "LintaoAmons/scratch.nvim",
    event = "VeryLazy",
    cmd = { "ScratchInfo" },
    dependencies = {
      "nvim-telescope/telescope.nvim",
    },
    keys = {
      { "<leader>fs", select_scratch_type, desc = "Scratch" },
      { "<leader>fS", open_scratch, desc = "Open scratch" },
      { "<leader>fi", "<cmd>ScratchInfo<cr>", desc = "Scratch info" },
      { "<leader>fN", "<cmd>ScratchWithName<cr>", desc = "Scratch with name" },
    },
    config = function()
      require("scratch").setup({
        filetypes = scratch_filetypes,
        scratch_file_dir = global_scratch_dir,
        window_cmd = "edit",
        file_picker = "telescope",
      })

      vim.api.nvim_create_user_command("ScratchInfo", scratch_info, {
        desc = "Show resolved scratch paths",
      })
    end,
  },
}
