return {
  name = "python-lsp-server",
  description = "Python LSP Server with Rope refactoring code actions",
  homepage = "https://github.com/python-lsp/python-lsp-server",
  licenses = { "MIT" },
  languages = { "Python" },
  categories = { "LSP" },
  source = {
    id = "pkg:pypi/python-lsp-server@1.15.0",
    extra_packages = { "pylsp-rope==0.1.17" },
  },
  bin = { pylsp = "pypi:pylsp" },
  neovim = { lspconfig = "pylsp" },
}
