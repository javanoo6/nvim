# Plugin update tracker

Baseline: 2026-11-10. Includes all 97 plugins in `lazy-lock.json`, including shared
and transitive dependencies. Baseline revisions describe the lockfile, not a
verification of installed checkouts. No plugins have been updated for this tracker.

## Update workflow

- Begin with committed changes and passing checks so rollback is straightforward.
- Pick one unchecked plugin below; review upstream changes and applicable
  [compatibility patch contracts](../core/compatibility-patches.md).
- Run `:Lazy update {plugin-name}` using the exact entry name. Review all changed
  revisions: dependency updates and build hooks may affect more than one plugin.
- Preserve configured branch/version constraints. An explicit commit pin requires
  deliberate review before changing it. Do not bypass compatibility revision gates
  merely by accepting new hashes.
- Inspect config/lockfile diffs, run `make check-compatibility` and `make check`,
  and perform the relevant interactive checks from the compatibility registry.
- Record the date, resulting revision, validation, and blockers. Check an entry
  only after accepting its update or explicitly deciding to retain its revision.
- Update affected findings in the [audit tracker](2026-11-10-configuration-audit.md).
  Keep each update separately reviewable before moving to the next plugin.
- If plugins must update together, document the coupling and validate the smallest
  necessary group together. Record rollback details when an update is rejected.

Mason packages, downloaded servers, parsers, and the standalone formatter submodule
have their own versions and are outside this plugin checklist.

## Pending plugins

Alphabetical order is for lookup, not a prescribed update sequence. Source references
identify specs mentioning a plugin when found; transitive dependencies may lack one.
Move accepted entries to Completed at the bottom, retaining their evidence.

- [ ] **Comment.nvim**
    - Baseline: `e30b7f2008e52442154b66f7c519bfd2f1e32acb`; lockfile branch: `master`.
    - Spec: `lua/plugins/coding.lua`.
    - Result: pending. Date: —. Accepted revision: —.
    - Validation / interactive checks / audit IDs / blockers: —.

- [ ] **FixCursorHold.nvim**
    - Baseline: `1900f89dc17c603eec29960f57c00bd9ae696495`; lockfile branch: `master`.
    - Spec: `lua/plugins/neotest.lua`.
    - Result: pending. Date: —. Accepted revision: —.
    - Validation / interactive checks / audit IDs / blockers: —.

- [ ] **LuaSnip**
    - Baseline: `0abc8f390b278c3b4aabc4c004ac8a088b65cf24`; lockfile branch: `master`.
    - Spec: `lua/plugins/completion.lua`.
    - Result: pending. Date: —. Accepted revision: —.
    - Validation / interactive checks / audit IDs / blockers: —.

- [ ] **actions-preview.nvim**
    - Baseline: `0ac9c2aa3cfc8c885321c0862b50b6b1c3392405`; lockfile branch: `master`.
    - Spec: `lua/plugins/lsp.lua`.
    - Result: pending. Date: —. Accepted revision: —.
    - Validation / interactive checks / audit IDs / blockers: —.

- [ ] **aerial.nvim**
    - Baseline: `28fe6e822ae344544c379d60fcb13c9519a1f08a`; lockfile branch: `master`.
    - Spec: `lua/plugins/aerial.lua`.
    - Result: pending. Date: —. Accepted revision: —.
    - Validation / interactive checks / audit IDs / blockers: —.

- [ ] **auto-save.nvim**
    - Baseline: `9aabcb8396224dcbf8d51c0c1d620d88a46e89d7`; lockfile branch: `main`.
    - Spec: `lua/plugins/auto-save.lua`.
    - Result: pending. Date: —. Accepted revision: —.
    - Validation / interactive checks / audit IDs / blockers: —.

- [ ] **auto-session**
    - Baseline: `6cde3874a9283c2db55627acca5f28e4fa402320`; lockfile branch: `main`.
    - Spec: `lua/plugins/sessions.lua`.
    - Review: compatibility registry records this revision; inspect its contracts before accepting an update.
    - Result: pending. Date: —. Accepted revision: —.
    - Validation / interactive checks / audit IDs / blockers: —.

- [ ] **better-escape.nvim**
    - Baseline: `3f4bc0b326606264ff75967f59091b5ddada0554`; lockfile branch: `master`.
    - Spec: `lua/plugins/editor.lua`.
    - Result: pending. Date: —. Accepted revision: —.
    - Validation / interactive checks / audit IDs / blockers: —.

- [ ] **bufferline.nvim**
    - Baseline: `655133c3b4c3e5e05ec549b9f8cc2894ac6f51b3`; lockfile branch: `main`.
    - Spec: `lua/plugins/ui.lua`.
    - Review: compatibility registry records this revision; inspect its contracts before accepting an update.
    - Result: pending. Date: —. Accepted revision: —.
    - Validation / interactive checks / audit IDs / blockers: —.

- [ ] **cmp-buffer**
    - Baseline: `b74fab3656eea9de20a9b8116afa3cfc4ec09657`; lockfile branch: `main`.
    - Spec: `lua/plugins/completion.lua`.
    - Review: compatibility registry records this revision; inspect its contracts before accepting an update.
    - Result: pending. Date: —. Accepted revision: —.
    - Validation / interactive checks / audit IDs / blockers: —.

- [ ] **cmp-cmdline**
    - Baseline: `d126061b624e0af6c3a556428712dd4d4194ec6d`; lockfile branch: `main`.
    - Spec: `lua/plugins/completion.lua`.
    - Result: pending. Date: —. Accepted revision: —.
    - Validation / interactive checks / audit IDs / blockers: —.

- [ ] **cmp-nvim-lsp**
    - Baseline: `cbc7b02bb99fae35cb42f514762b89b5126651ef`; lockfile branch: `main`.
    - Spec: `lua/plugins/intellij-lsp.lua`, `lua/plugins/lsp.lua`, `lua/plugins/completion.lua`.
    - Result: pending. Date: —. Accepted revision: —.
    - Validation / interactive checks / audit IDs / blockers: —.

- [ ] **cmp-nvim-lsp-signature-help**
    - Baseline: `fd3e882e56956675c620898bf1ffcf4fcbe7ec84`; lockfile branch: `main`.
    - Spec: `lua/plugins/completion.lua`.
    - Result: pending. Date: —. Accepted revision: —.
    - Validation / interactive checks / audit IDs / blockers: —.

- [ ] **cmp-path**
    - Baseline: `c642487086dbd9a93160e1679a1327be111cbc25`; lockfile branch: `main`.
    - Spec: `lua/plugins/completion.lua`.
    - Result: pending. Date: —. Accepted revision: —.
    - Validation / interactive checks / audit IDs / blockers: —.

- [ ] **cmp_luasnip**
    - Baseline: `98d9cb5c2c38532bd9bdb481067b20fea8f32e90`; lockfile branch: `master`.
    - Spec: `lua/plugins/completion.lua`.
    - Result: pending. Date: —. Accepted revision: —.
    - Validation / interactive checks / audit IDs / blockers: —.

- [ ] **conform.nvim**
    - Baseline: `619363c30309d29ffa631e67c8183f2a72caa373`; lockfile branch: `master`.
    - Spec: `lua/plugins/formatting.lua`.
    - Result: pending. Date: —. Accepted revision: —.
    - Validation / interactive checks / audit IDs / blockers: —.

- [ ] **diffview.nvim**
    - Baseline: `4516612fe98ff56ae0415a259ff6361a89419b0a`; lockfile branch: `main`.
    - Spec: `lua/plugins/git.lua`.
    - Result: pending. Date: —. Accepted revision: —.
    - Validation / interactive checks / audit IDs / blockers: —.

- [ ] **dressing.nvim**
    - Baseline: `2d7c2db2507fa3c4956142ee607431ddb2828639`; lockfile branch: `master`.
    - Spec: `lua/plugins/ui.lua`.
    - Result: pending. Date: —. Accepted revision: —.
    - Validation / interactive checks / audit IDs / blockers: —.

- [ ] **evergarden**
    - Baseline: `c2fd38fadc0e3c2b294328ce27c815d18ec3ebc4`; lockfile branch: `main`.
    - Result: pending. Date: —. Accepted revision: —.
    - Validation / interactive checks / audit IDs / blockers: —.

- [ ] **fidget.nvim**
    - Baseline: `6f793b2bcd2d35e201c09520f698bb763220908a`; lockfile branch: `main`.
    - Spec: `lua/plugins/lsp.lua`.
    - Result: pending. Date: —. Accepted revision: —.
    - Validation / interactive checks / audit IDs / blockers: —.

- [ ] **flash.nvim**
    - Baseline: `fcea7ff883235d9024dc41e638f164a450c14ca2`; lockfile branch: `main`.
    - Spec: `lua/plugins/motion.lua`.
    - Result: pending. Date: —. Accepted revision: —.
    - Validation / interactive checks / audit IDs / blockers: —.

- [ ] **friendly-snippets**
    - Baseline: `6cd7280adead7f586db6fccbd15d2cac7e2188b9`; lockfile branch: `main`.
    - Spec: `lua/plugins/completion.lua`.
    - Result: pending. Date: —. Accepted revision: —.
    - Validation / interactive checks / audit IDs / blockers: —.

- [ ] **git-conflict.nvim**
    - Baseline: `4bbfdd92d547d2862a75b4e80afaf30e73f7bbb4`; lockfile branch: `main`.
    - Spec: `lua/plugins/git.lua`.
    - Review: compatibility registry records this revision; inspect its contracts before accepting an update.
    - Result: pending. Date: —. Accepted revision: —.
    - Validation / interactive checks / audit IDs / blockers: —.

- [ ] **gitsigns.nvim**
    - Baseline: `eb60cc7b94c46005237fd34170d76f3a089a90aa`; lockfile branch: `main`.
    - Spec: `lua/plugins/git.lua`.
    - Review: compatibility registry records this revision; inspect its contracts before accepting an update.
    - Result: pending. Date: —. Accepted revision: —.
    - Validation / interactive checks / audit IDs / blockers: —.

- [ ] **glance.nvim**
    - Baseline: `e813e1230d7aba362df19e7d292f6f6766277af1`; lockfile branch: `fix/fs-read-nil-glance-list`.
    - Spec: `lua/plugins/glance.lua`.
    - Review: compatibility registry records this revision; inspect its contracts before accepting an update.
    - Caution: Preserve configured fork branch `fix/fs-read-nil-glance-list` and its unreadable-file fix.
    - Result: pending. Date: —. Accepted revision: —.
    - Validation / interactive checks / audit IDs / blockers: —.

- [ ] **gopher.nvim**
    - Baseline: `27ba078f14dd39fcd5e8a57d7009cdd77450ebbb`; lockfile branch: `main`.
    - Spec: `lua/plugins/go-extras.lua`.
    - Result: pending. Date: —. Accepted revision: —.
    - Validation / interactive checks / audit IDs / blockers: —.

- [ ] **grug-far.nvim**
    - Baseline: `c69859c1d5427ab5fc7ed12380ab521b4e336691`; lockfile branch: `main`.
    - Spec: `lua/plugins/grug-far.lua`.
    - Result: pending. Date: —. Accepted revision: —.
    - Validation / interactive checks / audit IDs / blockers: —.

- [ ] **harpoon**
    - Baseline: `1bc17e3e42ea3c46b33c0bbad6a880792692a1b3`; lockfile branch: `master`.
    - Spec: `lua/plugins/editor.lua`.
    - Result: pending. Date: —. Accepted revision: —.
    - Validation / interactive checks / audit IDs / blockers: —.

- [ ] **indent-blankline.nvim**
    - Baseline: `d28a3f70721c79e3c5f6693057ae929f3d9c0a03`; lockfile branch: `master`.
    - Spec: `lua/plugins/ui.lua`.
    - Result: pending. Date: —. Accepted revision: —.
    - Validation / interactive checks / audit IDs / blockers: —.

- [ ] **intellij-lsp.nvim**
    - Baseline: `77dc3e118a381e59f0d0b3e368e4b3a088280ab7`; lockfile branch: `main`.
    - Spec: `lua/plugins/intellij-lsp.lua`.
    - Review: compatibility registry records this revision; inspect its contracts before accepting an update.
    - Caution: Explicit commit pin; read `docs/java/java-workflow.md` and review the server bundle before changing it.
    - Result: pending. Date: —. Accepted revision: —.
    - Validation / interactive checks / audit IDs / blockers: —.

- [ ] **jb.nvim**
    - Baseline: `1cd3e9aeb81cd4b60b7b094a7900e6fc39d7dd79`; lockfile branch: `main`.
    - Spec: `lua/plugins/colorschemes.lua`.
    - Result: pending. Date: —. Accepted revision: —.
    - Validation / interactive checks / audit IDs / blockers: —.

- [ ] **kanagawa.nvim**
    - Baseline: `bb85e4bfc8d89b0e62c8fa53ccdd13d12e2f77b3`; lockfile branch: `master`.
    - Spec: `lua/plugins/colorschemes.lua`.
    - Result: pending. Date: —. Accepted revision: —.
    - Validation / interactive checks / audit IDs / blockers: —.

- [ ] **lazy.nvim**
    - Baseline: `306a05526ada86a7b30af95c5cc81ffba93fef97`; lockfile branch: `main`.
    - Spec: `lua/config/lazy.lua`.
    - Caution: Custom event registration in `lua/config/lazy.lua` uses manager internals.
    - Result: pending. Date: —. Accepted revision: —.
    - Validation / interactive checks / audit IDs / blockers: —.

- [ ] **lazygit.nvim**
    - Baseline: `a04ad0dbc725134edbee3a5eea29290976695357`; lockfile branch: `main`.
    - Spec: `lua/plugins/editor.lua`.
    - Result: pending. Date: —. Accepted revision: —.
    - Validation / interactive checks / audit IDs / blockers: —.

- [ ] **leetcode.nvim**
    - Baseline: `4e8b3683940a8377379ce9398e7f329e3560b42c`; lockfile branch: `master`.
    - Spec: `lua/plugins/leetcode.lua`.
    - Result: pending. Date: —. Accepted revision: —.
    - Validation / interactive checks / audit IDs / blockers: —.

- [ ] **lspkind.nvim**
    - Baseline: `c7274c48137396526b59d86232eabcdc7fed8a32`; lockfile branch: `master`.
    - Spec: `lua/plugins/completion.lua`.
    - Result: pending. Date: —. Accepted revision: —.
    - Validation / interactive checks / audit IDs / blockers: —.

- [ ] **lualine.nvim**
    - Baseline: `221ce6b2d999187044529f49da6554a92f740a96`; lockfile branch: `master`.
    - Spec: `lua/plugins/ui.lua`.
    - Result: pending. Date: —. Accepted revision: —.
    - Validation / interactive checks / audit IDs / blockers: —.

- [ ] **marks.nvim**
    - Baseline: `f353e8c08c50f39e99a9ed474172df7eddd89b72`; lockfile branch: `master`.
    - Spec: `lua/plugins/marks.lua`.
    - Result: pending. Date: —. Accepted revision: —.
    - Validation / interactive checks / audit IDs / blockers: —.

- [ ] **mason-lspconfig.nvim**
    - Baseline: `47059d71b42d74b0a1e9f61c1d99d301039c3b5b`; lockfile branch: `main`.
    - Spec: `lua/plugins/lsp.lua`.
    - Result: pending. Date: —. Accepted revision: —.
    - Validation / interactive checks / audit IDs / blockers: —.

- [ ] **mason-tool-installer.nvim**
    - Baseline: `443f1ef8b5e6bf47045cb2217b6f748a223cf7dc`; lockfile branch: `main`.
    - Spec: `lua/plugins/mason.lua`.
    - Result: pending. Date: —. Accepted revision: —.
    - Validation / interactive checks / audit IDs / blockers: —.

- [ ] **mason.nvim**
    - Baseline: `2a6940af80375532e5e9e7c1f2fc6319a1b7a69d`; lockfile branch: `main`.
    - Spec: `lua/plugins/mason.lua`, `lua/plugins/lsp.lua`.
    - Result: pending. Date: —. Accepted revision: —.
    - Validation / interactive checks / audit IDs / blockers: —.

- [ ] **md-render.nvim**
    - Baseline: `39c731abe5bf4cfa69c754968a7228299dcbdc69`; lockfile branch: `main`.
    - Spec: `lua/plugins/markdown.lua`.
    - Caution: Review `lua/util/markdown_images.lua`; check command-line overlays and synchronized scrolling.
    - Result: pending. Date: —. Accepted revision: —.
    - Validation / interactive checks / audit IDs / blockers: —.

- [ ] **mini.ai**
    - Baseline: `2f763720771e192bdf9d2e25bfae339930ba4231`; lockfile branch: `main`.
    - Spec: `lua/plugins/coding.lua`.
    - Result: pending. Date: —. Accepted revision: —.
    - Validation / interactive checks / audit IDs / blockers: —.

- [ ] **mini.surround**
    - Baseline: `19b44c1bbe4eecaf191896b8bec657d5fdd549e4`; lockfile branch: `main`.
    - Spec: `lua/plugins/coding.lua`.
    - Result: pending. Date: —. Accepted revision: —.
    - Validation / interactive checks / audit IDs / blockers: —.

- [ ] **neo-tree.nvim**
    - Baseline: `ebd66767191714e008ce73b769518a763ff31bdc`; lockfile branch: `v3.x`.
    - Spec: `lua/plugins/editor.lua`.
    - Result: pending. Date: —. Accepted revision: —.
    - Validation / interactive checks / audit IDs / blockers: —.

- [ ] **neotest**
    - Baseline: `fb84d87285698f7055f618083c351984449119b8`; lockfile branch: `master`.
    - Spec: `lua/plugins/neotest.lua`.
    - Review: compatibility registry records this revision; inspect its contracts before accepting an update.
    - Result: pending. Date: —. Accepted revision: —.
    - Validation / interactive checks / audit IDs / blockers: —.

- [ ] **neotest-golang**
    - Baseline: `542cbaf37f1233a2723ccd64ce8ed7e3acbd192b`; lockfile branch: `main`.
    - Spec: `lua/plugins/neotest.lua`.
    - Review: compatibility registry records this revision; inspect its contracts before accepting an update.
    - Result: pending. Date: —. Accepted revision: —.
    - Validation / interactive checks / audit IDs / blockers: —.

- [ ] **neotest-java**
    - Baseline: `78d236da986cca4dd95cb10b1250c4c6e1508240`; lockfile branch: `main`.
    - Spec: `lua/plugins/neotest.lua`.
    - Review: compatibility registry records this revision; inspect its contracts before accepting an update.
    - Result: pending. Date: —. Accepted revision: —.
    - Validation / interactive checks / audit IDs / blockers: —.

- [ ] **neotest-python**
    - Baseline: `51c453d57f8d5156671b42ea57fafa2e1c9fb641`; lockfile branch: `master`.
    - Spec: `lua/plugins/neotest.lua`.
    - Review: compatibility registry records this revision; inspect its contracts before accepting an update.
    - Result: pending. Date: —. Accepted revision: —.
    - Validation / interactive checks / audit IDs / blockers: —.

- [ ] **noice.nvim**
    - Baseline: `7bfd942445fb63089b59f97ca487d605e715f155`; lockfile branch: `main`.
    - Spec: `lua/plugins/noice.lua`.
    - Result: pending. Date: —. Accepted revision: —.
    - Validation / interactive checks / audit IDs / blockers: —.

- [ ] **nordic.nvim**
    - Baseline: `9fb62116b891184049c50ca6ffb0d3bc100a1a6e`; lockfile branch: `main`.
    - Spec: `lua/plugins/colorschemes.lua`.
    - Result: pending. Date: —. Accepted revision: —.
    - Validation / interactive checks / audit IDs / blockers: —.

- [ ] **nui.nvim**
    - Baseline: `de740991c12411b663994b2860f1a4fd0937c130`; lockfile branch: `main`.
    - Spec: `lua/plugins/editor.lua`, `lua/plugins/noice.lua`, `lua/plugins/leetcode.lua`.
    - Result: pending. Date: —. Accepted revision: —.
    - Validation / interactive checks / audit IDs / blockers: —.

- [ ] **nvim-autopairs**
    - Baseline: `7b9923abad60b903ece7c52940e1321d39eccc79`; lockfile branch: `master`.
    - Spec: `lua/plugins/coding.lua`.
    - Result: pending. Date: —. Accepted revision: —.
    - Validation / interactive checks / audit IDs / blockers: —.

- [ ] **nvim-cmp**
    - Baseline: `a1d504892f2bc56c2e79b65c6faded2fd21f3eca`; lockfile branch: `main`.
    - Spec: `lua/plugins/coding.lua`, `lua/plugins/completion.lua`.
    - Result: pending. Date: —. Accepted revision: —.
    - Validation / interactive checks / audit IDs / blockers: —.

- [ ] **nvim-dap**
    - Baseline: `9e848e09a697ee95302a3ef2dd43fd6eb709e570`; lockfile branch: `master`.
    - Spec: `lua/plugins/dap.lua`, `lua/plugins/intellij-lsp.lua`, `lua/plugins/neotest.lua`.
    - Result: pending. Date: —. Accepted revision: —.
    - Validation / interactive checks / audit IDs / blockers: —.

- [ ] **nvim-dap-go**
    - Baseline: `b4421153ead5d726603b02743ea40cf26a51ed5f`; lockfile branch: `main`.
    - Spec: `lua/plugins/dap.lua`.
    - Result: pending. Date: —. Accepted revision: —.
    - Validation / interactive checks / audit IDs / blockers: —.

- [ ] **nvim-dap-python**
    - Baseline: `1808458eba2b18f178f990e01376941a42c7f93b`; lockfile branch: `master`.
    - Spec: `lua/plugins/dap.lua`, `lua/plugins/python-venv.lua`.
    - Result: pending. Date: —. Accepted revision: —.
    - Validation / interactive checks / audit IDs / blockers: —.

- [ ] **nvim-dap-ui**
    - Baseline: `1a66cabaa4a4da0be107d5eda6d57242f0fe7e49`; lockfile branch: `master`.
    - Spec: `lua/plugins/dap.lua`.
    - Result: pending. Date: —. Accepted revision: —.
    - Validation / interactive checks / audit IDs / blockers: —.

- [ ] **nvim-dap-virtual-text**
    - Baseline: `fbdb48c2ed45f4a8293d0d483f7730d24467ccb6`; lockfile branch: `master`.
    - Spec: `lua/plugins/dap.lua`.
    - Result: pending. Date: —. Accepted revision: —.
    - Validation / interactive checks / audit IDs / blockers: —.

- [ ] **nvim-lint**
    - Baseline: `a219b2c9e5b4765e5c845aba119dad55806fcaf1`; lockfile branch: `master`.
    - Spec: `lua/plugins/linting.lua`.
    - Result: pending. Date: —. Accepted revision: —.
    - Validation / interactive checks / audit IDs / blockers: —.

- [ ] **nvim-lsp-file-operations**
    - Baseline: `b9c795d3973e8eec22706af14959bc60c579e771`; lockfile branch: `master`.
    - Spec: `lua/plugins/editor.lua`, `lua/plugins/intellij-lsp.lua`, `lua/plugins/lsp.lua`.
    - Result: pending. Date: —. Accepted revision: —.
    - Validation / interactive checks / audit IDs / blockers: —.

- [ ] **nvim-lspconfig**
    - Baseline: `d224a1920728ba129880efc700d4a0180ac4ecbb`; lockfile branch: `master`.
    - Spec: `lua/plugins/lsp.lua`, `lua/plugins/python-venv.lua`.
    - Result: pending. Date: —. Accepted revision: —.
    - Validation / interactive checks / audit IDs / blockers: —.

- [ ] **nvim-nio**
    - Baseline: `21f5324bfac14e22ba26553caf69ec76ae8a7662`; lockfile branch: `master`.
    - Spec: `lua/plugins/dap.lua`, `lua/plugins/neotest.lua`.
    - Review: compatibility registry records this revision; inspect its contracts before accepting an update.
    - Result: pending. Date: —. Accepted revision: —.
    - Validation / interactive checks / audit IDs / blockers: —.

- [ ] **nvim-notify**
    - Baseline: `8701bece920b38ea289b457f902e2ad184131a5d`; lockfile branch: `master`.
    - Spec: `lua/plugins/noice.lua`, `lua/plugins/ui.lua`.
    - Result: pending. Date: —. Accepted revision: —.
    - Validation / interactive checks / audit IDs / blockers: —.

- [ ] **nvim-spider**
    - Baseline: `7f021426d4a615ea8f11cabed434b1f20376abae`; lockfile branch: `main`.
    - Spec: `lua/plugins/motion.lua`.
    - Result: pending. Date: —. Accepted revision: —.
    - Validation / interactive checks / audit IDs / blockers: —.

- [ ] **nvim-treehopper**
    - Baseline: `e3861c0231631c6af317d6746bb78fdb428a58f3`; lockfile branch: `master`.
    - Spec: `lua/plugins/motion.lua`.
    - Result: pending. Date: —. Accepted revision: —.
    - Validation / interactive checks / audit IDs / blockers: —.

- [ ] **nvim-treesitter**
    - Baseline: `4916d6592ede8c07973490d9322f187e07dfefac`; lockfile branch: `main`.
    - Spec: `lua/plugins/go-extras.lua`, `lua/plugins/aerial.lua`, `lua/plugins/treesitter.lua`, `lua/plugins/motion.lua`, `lua/plugins/neotest.lua`.
    - Result: pending. Date: —. Accepted revision: —.
    - Validation / interactive checks / audit IDs / blockers: —.

- [ ] **nvim-treesitter-textobjects**
    - Baseline: `851e865342e5a4cb1ae23d31caf6e991e1c99f1e`; lockfile branch: `main`.
    - Spec: `lua/plugins/treesitter.lua`.
    - Result: pending. Date: —. Accepted revision: —.
    - Validation / interactive checks / audit IDs / blockers: —.

- [ ] **nvim-ts-context-commentstring**
    - Baseline: `6141a40173c6efa98242dc951ed4b6f892c97027`; lockfile branch: `main`.
    - Spec: `lua/plugins/coding.lua`.
    - Result: pending. Date: —. Accepted revision: —.
    - Validation / interactive checks / audit IDs / blockers: —.

- [ ] **nvim-web-devicons**
    - Baseline: `dad71387de386a946b123079d0e53f23028f3abd`; lockfile branch: `master`.
    - Spec: `lua/plugins/editor.lua`, `lua/plugins/trouble.lua`, `lua/plugins/aerial.lua`, `lua/plugins/ui.lua`.
    - Result: pending. Date: —. Accepted revision: —.
    - Validation / interactive checks / audit IDs / blockers: —.

- [ ] **nvim-window-picker**
    - Baseline: `6382540b2ae5de6c793d4aa2e3fe6dbb518505ec`; lockfile branch: `main`.
    - Spec: `lua/plugins/editor.lua`.
    - Result: pending. Date: —. Accepted revision: —.
    - Validation / interactive checks / audit IDs / blockers: —.

- [ ] **obsidian.nvim**
    - Baseline: `ae1f76a75c7ce36866e1d9342a8f6f5b9c2caf9b`; lockfile branch: `main`.
    - Spec: `lua/plugins/obsidian.lua`.
    - Result: pending. Date: —. Accepted revision: —.
    - Validation / interactive checks / audit IDs / blockers: —.

- [ ] **oil.nvim**
    - Baseline: `b73018b75affd13fa38e2fc94ef753b465f770d7`; lockfile branch: `master`.
    - Spec: `lua/plugins/editor.lua`.
    - Result: pending. Date: —. Accepted revision: —.
    - Validation / interactive checks / audit IDs / blockers: —.

- [ ] **onenord.nvim**
    - Baseline: `5240bfb79bcab7e03508626c5283cfc417b79169`; lockfile branch: `main`.
    - Spec: `lua/plugins/colorschemes.lua`.
    - Result: pending. Date: —. Accepted revision: —.
    - Validation / interactive checks / audit IDs / blockers: —.

- [ ] **oxocarbon.nvim**
    - Baseline: `cf49e389c22dab56224e43ae16422ddcd5b61b28`; lockfile branch: `main`.
    - Spec: `lua/plugins/colorschemes.lua`.
    - Result: pending. Date: —. Accepted revision: —.
    - Validation / interactive checks / audit IDs / blockers: —.

- [ ] **persist-toggle.nvim**
    - Baseline: `06ac63f8bda494d52fd002d3ae4cd14ab5d152eb`; lockfile branch: `main`.
    - Spec: `lua/plugins/persist-toggle.lua`.
    - Result: pending. Date: —. Accepted revision: —.
    - Validation / interactive checks / audit IDs / blockers: —.

- [ ] **plenary.nvim**
    - Baseline: `74b06c6c75e4eeb3108ec01852001636d85a932b`; lockfile branch: `master`.
    - Spec: `lua/plugins/editor.lua`, `lua/plugins/go-extras.lua`, `lua/plugins/todo-comments.lua`, `lua/plugins/obsidian.lua`, `lua/plugins/leetcode.lua`,
      `lua/plugins/python-venv.lua`, `lua/plugins/neotest.lua`.
    - Result: pending. Date: —. Accepted revision: —.
    - Validation / interactive checks / audit IDs / blockers: —.

- [ ] **poimandres.nvim**
    - Baseline: `a488957d803943a4201ac3b774913fcafa9e6b3a`; lockfile branch: `main`.
    - Spec: `lua/plugins/colorschemes.lua`.
    - Result: pending. Date: —. Accepted revision: —.
    - Validation / interactive checks / audit IDs / blockers: —.

- [ ] **project.nvim**
    - Baseline: `8c6bad7d22eef1b71144b401c9f74ed01526a4fb`; lockfile branch: `main`.
    - Spec: `lua/plugins/projects.lua`.
    - Result: pending. Date: —. Accepted revision: —.
    - Validation / interactive checks / audit IDs / blockers: —.

- [ ] **quicker.nvim**
    - Baseline: `4a6883cb13fe097a20a046eb55f6dffd239276e3`; lockfile branch: `master`.
    - Spec: `lua/plugins/quicker.lua`.
    - Result: pending. Date: —. Accepted revision: —.
    - Validation / interactive checks / audit IDs / blockers: —.

- [ ] **rainbow-delimiters.nvim**
    - Baseline: `a798325b7f36acc62741d1029930a7b96d4dd4bf`; lockfile branch: `master`.
    - Spec: `lua/plugins/treesitter.lua`.
    - Result: pending. Date: —. Accepted revision: —.
    - Validation / interactive checks / audit IDs / blockers: —.

- [ ] **scratch.nvim**
    - Baseline: `01e4fa9347941f5fe6bd0ec2581ffc12d3234d66`; lockfile branch: `main`.
    - Spec: `lua/plugins/scratch.lua`.
    - Result: pending. Date: —. Accepted revision: —.
    - Validation / interactive checks / audit IDs / blockers: —.

- [ ] **spring-boot.nvim**
    - Baseline: `218c0c26c14d99feca778e4d13f5ec3e8b1b60f0`; lockfile branch: `main`.
    - Result: pending. Date: —. Accepted revision: —.
    - Validation / interactive checks / audit IDs / blockers: —.

- [ ] **telescope-fzf-native.nvim**
    - Baseline: `b25b749b9db64d375d782094e2b9dce53ad53a40`; lockfile branch: `main`.
    - Spec: `lua/plugins/editor.lua`.
    - Result: pending. Date: —. Accepted revision: —.
    - Validation / interactive checks / audit IDs / blockers: —.

- [ ] **telescope.nvim**
    - Baseline: `427b576c16792edad01a92b89721d923c19ad60f`; lockfile branch: `master`.
    - Spec: `lua/plugins/editor.lua`, `lua/plugins/scratch.lua`, `lua/plugins/leetcode.lua`, `lua/plugins/projects.lua`.
    - Result: pending. Date: —. Accepted revision: —.
    - Validation / interactive checks / audit IDs / blockers: —.

- [ ] **themery.nvim**
    - Baseline: `bfa58f4b279d21cb515b28023e1b68ec908584b2`; lockfile branch: `main`.
    - Spec: `lua/plugins/colorschemes.lua`.
    - Result: pending. Date: —. Accepted revision: —.
    - Validation / interactive checks / audit IDs / blockers: —.

- [ ] **tiny-inline-diagnostic.nvim**
    - Baseline: `6264451f14119d63a52580e5198d6baf8518b0b2`; lockfile branch: `main`.
    - Spec: `lua/plugins/lsp.lua`.
    - Result: pending. Date: —. Accepted revision: —.
    - Validation / interactive checks / audit IDs / blockers: —.

- [ ] **todo-comments.nvim**
    - Baseline: `31e3c38ce9b29781e4422fc0322eb0a21f4e8668`; lockfile branch: `main`.
    - Spec: `lua/plugins/todo-comments.lua`.
    - Result: pending. Date: —. Accepted revision: —.
    - Validation / interactive checks / audit IDs / blockers: —.

- [ ] **toggleterm.nvim**
    - Baseline: `50ea089fc548917cc3cc16b46a8211833b9e3c7c`; lockfile branch: `main`.
    - Spec: `lua/plugins/terminal.lua`.
    - Result: pending. Date: —. Accepted revision: —.
    - Validation / interactive checks / audit IDs / blockers: —.

- [ ] **tokyonight.nvim**
    - Baseline: `cdc07ac78467a233fd62c493de29a17e0cf2b2b6`; lockfile branch: `main`.
    - Spec: `lua/plugins/colorschemes.lua`.
    - Result: pending. Date: —. Accepted revision: —.
    - Validation / interactive checks / audit IDs / blockers: —.

- [ ] **trouble.nvim**
    - Baseline: `bd67efe408d4816e25e8491cc5ad4088e708a69a`; lockfile branch: `main`.
    - Spec: `lua/plugins/trouble.lua`.
    - Result: pending. Date: —. Accepted revision: —.
    - Validation / interactive checks / audit IDs / blockers: —.

- [ ] **undotree**
    - Baseline: `6fa6b57cda8459e1e4b2ca34df702f55242f4e4d`; lockfile branch: `master`.
    - Spec: `lua/plugins/undotree.lua`.
    - Result: pending. Date: —. Accepted revision: —.
    - Validation / interactive checks / audit IDs / blockers: —.

- [ ] **vague.nvim**
    - Baseline: `49fe06ad33d8847b931ba4279197bda222374cd1`; lockfile branch: `main`.
    - Spec: `lua/plugins/colorschemes.lua`.
    - Result: pending. Date: —. Accepted revision: —.
    - Validation / interactive checks / audit IDs / blockers: —.

- [ ] **venv-selector.nvim**
    - Baseline: `cc4bb3975de8835291f9bb45889e96c6b2795fc4`; lockfile branch: `main`.
    - Spec: `lua/plugins/python-venv.lua`.
    - Result: pending. Date: —. Accepted revision: —.
    - Validation / interactive checks / audit IDs / blockers: —.

- [ ] **vim-illuminate**
    - Baseline: `8629e6b2dfa8c66677b9d489eb02480cbcfa9599`; lockfile branch: `master`.
    - Spec: `lua/plugins/ui.lua`.
    - Result: pending. Date: —. Accepted revision: —.
    - Validation / interactive checks / audit IDs / blockers: —.

- [ ] **which-key.nvim**
    - Baseline: `3aab2147e74890957785941f0c1ad87d0a44c15a`; lockfile branch: `main`.
    - Spec: `lua/plugins/ui.lua`.
    - Review: compatibility registry records this revision; inspect its contracts before accepting an update.
    - Result: pending. Date: —. Accepted revision: —.
    - Validation / interactive checks / audit IDs / blockers: —.

- [ ] **yanky.nvim**
    - Baseline: `020c22d0cfa60358569e49d1d7b91630f175aef0`; lockfile branch: `main`.
    - Spec: `lua/plugins/coding.lua`.
    - Result: pending. Date: —. Accepted revision: —.
    - Validation / interactive checks / audit IDs / blockers: —.

## Completed

No plugin updates reviewed yet. Retain baseline revisions and validation evidence
when moving accepted entries here.
