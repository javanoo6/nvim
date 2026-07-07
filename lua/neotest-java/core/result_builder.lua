local log = require("neotest-java.logger")
local JunitResult = require("neotest-java.model.junit_result")

local REPORT_FILE_NAMES_PATTERN = "TEST-.+%.xml$"

local clean_id = function(str)
  return str:gsub("%(.*", "")
end

--- @return table <string, neotest-java.JunitResult[]>
local function group_by_method_base(testcases)
  local groups = {}
  for _, jres in ipairs(testcases) do
    local key = jres:id()
    groups[key] = groups[key] or {}
    table.insert(groups[key], jres)
  end
  return groups
end

local function find_tree_result_id(tree, result_id)
  local cleaned_result_id = clean_id(result_id)
  local cleaned_match = nil

  for _, pos in tree:iter() do
    local pos_id = pos.id
    if pos_id == result_id then
      return pos_id, true
    end

    if not cleaned_match and clean_id(pos_id) == cleaned_result_id then
      cleaned_match = pos_id
    end
  end

  return cleaned_match or result_id, cleaned_match ~= nil
end

-- -----------------------------------------------------------------------------
-- Public API
-- -----------------------------------------------------------------------------

--- @class neotest-java.ResultBuilder
--- @field build_results fun(spec: neotest.RunSpec, result: neotest.StrategyResult, tree: neotest.Tree): table<string, neotest.Result>

--- @class neotest-java.ResultBuilderDeps
--- @field scan_dir fun(dir: neotest-java.Path, opts: { search_patterns: string[] }): neotest-java.Path[]
--- @field junit_result_reader { read_all: fun(paths: neotest-java.Path[]): neotest-java.JunitResult[] }
--- @field remove_file fun(filepath: string): boolean, string?
--- @field tempname_fn fun(): string

--- @param deps neotest-java.ResultBuilderDeps
--- @return neotest-java.ResultBuilder
local ResultBuilder = function(deps)
  deps = deps or {}
  assert(deps.scan_dir, "scan_dir should not be nil")
  assert(deps.junit_result_reader, "junit_result_reader should not be nil")
  assert(deps.remove_file, "remove_file should not be nil")
  assert(deps.tempname_fn, "tempname_fn should not be nil")

  local find_report_files = function(dir)
    return deps.scan_dir(dir, { search_patterns = { REPORT_FILE_NAMES_PATTERN } })
  end

  return {
    --- @param spec neotest.RunSpec
    --- @param result neotest.StrategyResult
    --- @param tree neotest.Tree
    --- @return table<string, neotest.Result>
    build_results = function(spec, result, tree)
      if result.code ~= 0 and result.code ~= 1 then
        local node = tree:data()
        return { [node.id] = JunitResult.ERROR(node.id, result.output, deps.tempname_fn) }
      end

      if spec.context.strategy == "dap" then
        spec.context.terminated_command_event.wait()
      end

      local report_files = find_report_files(spec.context.reports_dir)
      local testcases = deps.junit_result_reader.read_all(report_files)
      local groups = group_by_method_base(testcases)

      local results = {}

      for id, items in pairs(groups) do
        local result_id, matched_tree = find_tree_result_id(tree, id)

        if #items == 1 then
          --- @type neotest-java.JunitResult
          local jres = items[1]

          results[result_id] = jres:result()
        elseif matched_tree then
          results[result_id] = JunitResult.merge_results(items, deps.tempname_fn)
        else
          log.error("Could not find matching test node for results with id: " .. items[1]:id())
        end
      end

      -- Clean up report files after processing
      for _, report_file in ipairs(report_files) do
        local filepath = tostring(report_file)
        local ok, err = deps.remove_file(filepath)
        if not ok then
          log.debug("Could not remove report file: " .. filepath .. " - " .. tostring(err or "unknown error"))
        end
      end

      return results
    end,
  }
end

return ResultBuilder
