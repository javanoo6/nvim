local M = {}

local marker_pattern = "^(<<<<<<<|=======|>>>>>>>)"
local ours_pattern = "^<<<<<<<"
local base_pattern = "^|||||||"
local separator_pattern = "^======="
local theirs_pattern = "^>>>>>>>"

local function git_root()
  local root = require("util").get_root()
  local output = vim.fn.systemlist({ "git", "-C", root, "rev-parse", "--show-toplevel" })
  if vim.v.shell_error ~= 0 or not output[1] or output[1] == "" then
    return nil
  end
  return output[1]
end

local function tracked_files(root)
  local output = vim.fn.system({ "git", "-C", root, "ls-files", "-z" })
  if vim.v.shell_error ~= 0 then
    return nil
  end
  return vim.split(output, "\0", { plain = true, trimempty = true })
end

local function is_markdown(path)
  return path:match("%.md$") or path:match("%.markdown$")
end

local function marker_items_for_file(root, file)
  local path = root .. "/" .. file
  local ok, lines = pcall(vim.fn.readfile, path)
  if not ok then
    return {}
  end

  local items = {}
  local in_markdown_fence = false
  local skip_fences = is_markdown(file)

  for index, line in ipairs(lines) do
    if skip_fences and (line:match("^%s*```") or line:match("^%s*~~~")) then
      in_markdown_fence = not in_markdown_fence
    elseif not in_markdown_fence and line:match(marker_pattern) then
      table.insert(items, {
        filename = path,
        lnum = index,
        col = 1,
        text = line,
      })
    end
  end

  return items
end

local function current_lines()
  return vim.api.nvim_buf_get_lines(0, 0, -1, false)
end

local function conflict_blocks()
  local lines = current_lines()
  local blocks = {}
  local index = 1

  while index <= #lines do
    if lines[index]:match(ours_pattern) then
      local block = {
        start = index,
        base = nil,
        separator = nil,
        finish = nil,
      }
      index = index + 1

      while index <= #lines do
        local line = lines[index]
        if not block.base and line:match(base_pattern) then
          block.base = index
        elseif line:match(separator_pattern) then
          block.separator = index
        elseif line:match(theirs_pattern) then
          block.finish = index
          break
        end
        index = index + 1
      end

      if block.separator and block.finish then
        table.insert(blocks, block)
      end
    end

    index = index + 1
  end

  return lines, blocks
end

local function block_at_cursor(blocks)
  local cursor = vim.api.nvim_win_get_cursor(0)[1]

  for _, block in ipairs(blocks) do
    if cursor >= block.start and cursor <= block.finish then
      return block
    end
  end

  for _, block in ipairs(blocks) do
    if block.start > cursor then
      return block
    end
  end

  return blocks[1]
end

local function slice(lines, first, last)
  if not first or not last or first > last then
    return {}
  end

  local result = {}
  for index = first, last do
    table.insert(result, lines[index])
  end
  return result
end

local function replacement_lines(lines, block, side)
  local ours_end = (block.base or block.separator) - 1
  local ours = slice(lines, block.start + 1, ours_end)
  local theirs = slice(lines, block.separator + 1, block.finish - 1)

  if side == "ours" then
    return ours
  elseif side == "theirs" then
    return theirs
  elseif side == "both" then
    return vim.list_extend(ours, theirs)
  elseif side == "none" then
    return {}
  end

  error("Unknown conflict side: " .. tostring(side))
end

function M.choose(side)
  local lines, blocks = conflict_blocks()
  local block = block_at_cursor(blocks)

  if not block then
    vim.notify("No conflict marker block found", vim.log.levels.WARN)
    return
  end

  vim.api.nvim_buf_set_lines(0, block.start - 1, block.finish, false, replacement_lines(lines, block, side))
end

function M.next()
  local _, blocks = conflict_blocks()
  if vim.tbl_isempty(blocks) then
    vim.notify("No conflict marker block found", vim.log.levels.WARN)
    return
  end

  local cursor = vim.api.nvim_win_get_cursor(0)[1]
  for _, block in ipairs(blocks) do
    if block.start > cursor then
      vim.api.nvim_win_set_cursor(0, { block.start, 0 })
      return
    end
  end

  vim.api.nvim_win_set_cursor(0, { blocks[1].start, 0 })
end

function M.prev()
  local _, blocks = conflict_blocks()
  if vim.tbl_isempty(blocks) then
    vim.notify("No conflict marker block found", vim.log.levels.WARN)
    return
  end

  local cursor = vim.api.nvim_win_get_cursor(0)[1]
  for index = #blocks, 1, -1 do
    if blocks[index].start < cursor then
      vim.api.nvim_win_set_cursor(0, { blocks[index].start, 0 })
      return
    end
  end

  vim.api.nvim_win_set_cursor(0, { blocks[#blocks].start, 0 })
end

function M.find(opts)
  opts = opts or {}

  local root = git_root()
  if not root then
    vim.notify("Not inside a Git repository", vim.log.levels.WARN)
    return
  end

  local files = tracked_files(root)
  if not files then
    vim.notify("Could not list tracked files", vim.log.levels.ERROR)
    return
  end

  local items = {}
  for _, file in ipairs(files) do
    for _, item in ipairs(marker_items_for_file(root, file)) do
      table.insert(items, item)
    end
  end

  if vim.tbl_isempty(items) then
    vim.notify("No committed conflict markers found")
    return
  end

  vim.fn.setqflist({}, "r", {
    title = "Committed conflict markers",
    items = items,
  })
  vim.cmd.copen()

  if not opts.list_only then
    pcall(vim.cmd.cfirst)
  end

  vim.notify(("Found %d conflict marker lines"):format(#items))
end

function M.setup()
  vim.api.nvim_create_user_command("GitConflictMarkers", function(command)
    M.find({ list_only = command.bang })
  end, {
    bang = true,
    desc = "Find committed Git conflict markers in tracked files",
  })
end

return M
