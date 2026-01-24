-- ./lua/lang/java/keymaps.lua

-- Java Keymaps: All Java-related keybindings
-- Centralizes all jdtls and java-specific keymaps

local M = {}

function M.setup(bufnr, jdtls)
	local opts = function(desc)
		return { buffer = bufnr, silent = true, desc = desc }
	end

	local map = vim.keymap.set

	-- Navigation (LSP)
	map("n", "gd", vim.lsp.buf.definition, opts("Go to definition"))
	map("n", "gD", vim.lsp.buf.declaration, opts("Go to declaration"))
	map("n", "gr", vim.lsp.buf.references, opts("Go to references"))
	map("n", "gI", vim.lsp.buf.implementation, opts("Go to implementation"))
	map("n", "gy", vim.lsp.buf.type_definition, opts("Go to type definition"))
	map("n", "K", vim.lsp.buf.hover, opts("Hover"))
	map("n", "gK", vim.lsp.buf.signature_help, opts("Signature help"))

	-- Code actions
	map("n", "<leader>ca", vim.lsp.buf.code_action, opts("Code action"))
	map("n", "<leader>cr", vim.lsp.buf.rename, opts("Rename"))

	-- jdtls specific - refactoring
	map("n", "<leader>jo", jdtls.organize_imports, opts("Organize imports"))
	map("n", "<leader>jv", jdtls.extract_variable, opts("Extract variable"))
	map("v", "<leader>jv", function() jdtls.extract_variable(true) end, opts("Extract variable"))
	map("n", "<leader>jc", jdtls.extract_constant, opts("Extract constant"))
	map("v", "<leader>jc", function() jdtls.extract_constant(true) end, opts("Extract constant"))
	map("v", "<leader>jm", function() jdtls.extract_method(true) end, opts("Extract method"))
	map("n", "<leader>ju", jdtls.update_projects_config, opts("Update project config"))

	-- Testing
	map("n", "<leader>tc", jdtls.test_class, opts("Test class"))
	map("n", "<leader>tm", jdtls.test_nearest_method, opts("Test nearest method"))
	map("n", "<leader>tg", function() require("jdtls.tests").generate() end, opts("Generate test"))
	map("n", "<leader>ts", function() require("jdtls.tests").goto_subjects() end, opts("Go to test subject"))
end

return M
