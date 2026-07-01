-- ./lua/plugins/lsp-selection-range.lua

-- LSP Selection Range - semantic expand/shrink selection
return {
  "ptimoney/lsp-selection-range.nvim",
  event = "LspAttach",
  config = function()
    require("lsp-selection-range").setup({
      keymaps = {
        expand = "<A-o>",
        shrink = "<A-i>",
      },
      modes = { "n", "v" },
      clear_state_on_mode_exit = true,
    })

    vim.api.nvim_create_autocmd("LspAttach", {
      group = vim.api.nvim_create_augroup("custom_lsp_selection_range_aliases", { clear = true }),
      callback = function(args)
        local client = vim.lsp.get_client_by_id(args.data.client_id)
        if not client or not client.supports_method("textDocument/selectionRange") then
          return
        end

        local opts = { buffer = args.buf, remap = true, silent = true }
        vim.keymap.set({ "n", "x" }, "<CR>", "<A-o>", vim.tbl_extend("force", opts, { desc = "LSP: Expand selection" }))
        vim.keymap.set("x", "<Tab><CR>", "<A-i>", vim.tbl_extend("force", opts, { desc = "LSP: Shrink selection" }))
      end,
    })
  end,
}
