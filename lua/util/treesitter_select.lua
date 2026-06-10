local M = {}

local function node_range(node)
  local start_row, start_col, end_row, end_col = node:range()
  return {
    start_row = start_row,
    start_col = start_col,
    end_row = end_row,
    end_col = end_col,
  }
end

local function range_contains(outer, inner)
  local starts_before = outer.start_row < inner.start_row or (outer.start_row == inner.start_row and outer.start_col <= inner.start_col)
  local ends_after = outer.end_row > inner.end_row or (outer.end_row == inner.end_row and outer.end_col >= inner.end_col)
  return starts_before and ends_after
end

local function visual_range()
  local mode = vim.api.nvim_get_mode().mode
  local start_pos
  local end_pos

  if mode:match("[vV\022]") then
    start_pos = vim.fn.getpos("v")
    end_pos = vim.fn.getcurpos()
  else
    start_pos = vim.fn.getpos("'<")
    end_pos = vim.fn.getpos("'>")
  end

  local range = {
    start_row = start_pos[2] - 1,
    start_col = start_pos[3] - 1,
    end_row = end_pos[2] - 1,
    end_col = end_pos[3],
  }

  if range.start_row < 0 or range.end_row < 0 then
    return nil
  end

  if range.start_row > range.end_row or (range.start_row == range.end_row and range.start_col > range.end_col) then
    range.start_row, range.end_row = range.end_row, range.start_row
    range.start_col, range.end_col = range.end_col, range.start_col
  end

  return range
end

local function parser_root()
  local ok, parser = pcall(vim.treesitter.get_parser, 0)
  if not ok or not parser then
    return nil
  end

  local tree = parser:parse()[1]
  return tree and tree:root() or nil
end

local function smallest_enclosing_node(root, target)
  local best

  local function visit(node)
    local range = node_range(node)
    if not range_contains(range, target) then
      return
    end

    best = node

    for child in node:iter_children() do
      visit(child)
    end
  end

  visit(root)
  return best
end

local function named_parent(node)
  local parent = node and node:parent()
  while parent and not parent:named() do
    parent = parent:parent()
  end
  return parent
end

local function named_child_containing(node, target)
  for child in node:iter_children() do
    if child:named() and range_contains(node_range(child), target) then
      return child
    end
  end
end

local function first_named_child(node)
  for child in node:iter_children() do
    if child:named() then
      return child
    end
  end
end

local function next_named_sibling(node)
  local sibling = node and node:next_sibling()
  while sibling and not sibling:named() do
    sibling = sibling:next_sibling()
  end
  return sibling
end

local function select_node(node)
  local range = node_range(node)
  local end_col = math.max(range.end_col, 1)

  vim.fn.setpos("'<", { 0, range.start_row + 1, range.start_col + 1, 0 })
  vim.fn.setpos("'>", { 0, range.end_row + 1, end_col, 0 })

  vim.schedule(function()
    vim.cmd("normal! gv")
  end)
end

local function current_node()
  local root = parser_root()
  if not root then
    vim.notify("Treesitter parser unavailable for this buffer", vim.log.levels.WARN)
    return nil
  end

  local range = visual_range()
  if not range then
    vim.notify("No active visual selection found", vim.log.levels.WARN)
    return nil
  end

  return smallest_enclosing_node(root, range)
end

function M.select_parent(count)
  local node = current_node()
  for _ = 1, count or 1 do
    node = named_parent(node)
    if not node then
      return
    end
  end

  select_node(node)
end

function M.select_child(count)
  local target = visual_range()
  local node = current_node()
  if not target then
    return
  end
  for _ = 1, count or 1 do
    if not node then
      return
    end
    node = named_child_containing(node, target) or first_named_child(node)
  end

  if node then
    select_node(node)
  end
end

function M.select_next(count)
  local node = current_node()
  for _ = 1, count or 1 do
    node = next_named_sibling(node)
    if not node then
      return
    end
  end

  select_node(node)
end

return M
