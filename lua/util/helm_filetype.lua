local M = {}

local function chart_filetype(path)
  local root = vim.fs.root(path, { { "Chart.yaml", "Chart.yml" } })
  if not root then
    return
  end
  local relative = vim.fs.relpath(root, path)
  if not relative then
    return
  end
  if relative:match("^templates/.*%.ya?ml$") or relative:match("^templates/.*%.tpl$") or relative:match("^templates/.*%.txt$") then
    return "helm"
  end
  if relative:match("^Chart%.ya?ml$") or relative:match("^values%.ya?ml$") or relative:match("^values%-[^/]+%.ya?ml$") then
    return "yaml.helm-values"
  end
end

function M.setup()
  -- Return nil outside charts so ordinary YAML/template detection can proceed.
  vim.filetype.add({
    pattern = {
      [".*/templates/.*%.ya?ml"] = chart_filetype,
      [".*/templates/.*%.tpl"] = chart_filetype,
      [".*/templates/.*%.txt"] = chart_filetype,
      [".*/Chart%.ya?ml"] = chart_filetype,
      [".*/values%.ya?ml"] = chart_filetype,
      [".*/values%-[^/]+%.ya?ml"] = chart_filetype,
    },
  })
end

return M
