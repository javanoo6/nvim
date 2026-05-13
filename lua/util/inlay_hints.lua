local M = {}

local function each_loaded_buffer(callback)
	for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
		if vim.api.nvim_buf_is_loaded(bufnr) then
			callback(bufnr)
		end
	end
end

local function set_enabled(bufnr, enabled)
	vim.lsp.inlay_hint.enable(enabled, { bufnr = bufnr })
end

function M.is_enabled()
	return vim.g.inlay_hints_enabled ~= false
end

function M.set_enabled(enabled, opts)
	opts = opts or {}
	vim.g.inlay_hints_enabled = enabled

	if opts.notify ~= false then
		vim.notify("Inlay hints: " .. (enabled and "on" or "off"))
	end

	each_loaded_buffer(function(bufnr)
		set_enabled(bufnr, enabled)
	end)
end

function M.apply_for_buffer(bufnr)
	bufnr = bufnr or vim.api.nvim_get_current_buf()
	set_enabled(bufnr, M.is_enabled())
end

function M.toggle()
	M.set_enabled(not M.is_enabled())
end

vim.g.inlay_hints_enabled = vim.g.inlay_hints_enabled ~= false

return M
