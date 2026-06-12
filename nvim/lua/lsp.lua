-- ── Global defaults ───────────────────────────────────────────────────────────
vim.lsp.config("*", {
  capabilities = {
    textDocument = {
      semanticTokens = { multilineTokenSupport = true },
    },
  },
  root_markers = { ".git" },
})

-- ── Diagnostics ───────────────────────────────────────────────────────────────
vim.diagnostic.config({
  virtual_lines    = { only_current_line = true },
  virtual_text     = false,
  signs            = true,
  underline        = true,
  update_in_insert = false,
  severity_sort    = true,
  float = {
    border = "single",
    source = true,
  },
})

-- ── clangd (C / C++ / ASM) ───────────────────────────────────────────────────
vim.lsp.config("clangd", {
  cmd       = { "clangd", "--background-index", "--clang-tidy", "--header-insertion=iwyu" },
  filetypes = { "c", "cpp", "objc", "objcpp", "asm" },
  root_markers = { "compile_commands.json", "compile_flags.txt", "CMakeLists.txt", "Makefile", ".git" },
})

-- ── pyright (Python – types) ─────────────────────────────────────────────────
vim.lsp.config("pyright", {
  cmd       = { "pyright-langserver", "--stdio" },
  filetypes = { "python" },
  root_markers = { "pyproject.toml", "setup.py", "setup.cfg", "requirements.txt", ".git" },
  settings = {
    python = {
      analysis = {
        autoSearchPaths        = true,
        useLibraryCodeForTypes = true,
        diagnosticMode         = "workspace",
      },
    },
  },
})

-- ── gopls (Go) ───────────────────────────────────────────────────────────────
vim.lsp.config("gopls", {
  cmd       = { "gopls" },
  filetypes = { "go", "gomod", "gosum", "gowork" },
  root_markers = { "go.mod", "go.work", ".git" },
  settings = {
    gopls = {
      analyses  = { unusedparams = true, shadow = true },
      staticcheck = true,
    },
  },
})

-- ── lua-language-server (Lua / Neovim config) ────────────────────────────────
vim.lsp.config("lua_ls", {
  cmd       = { "lua-language-server" },
  filetypes = { "lua" },
  root_markers = { ".luarc.json", ".luarc.jsonc", ".git" },
  settings = {
    Lua = {
      runtime = { version = "LuaJIT" },           -- Neovim uses LuaJIT
      workspace = {
        checkThirdParty = false,
        library = vim.api.nvim_get_runtime_file("", true),
      },
      diagnostics = { globals = { "vim" } },      -- suppress vim global warnings
      telemetry    = { enable = false },
    },
  },
})

-- ── nixd (Nix) ───────────────────────────────────────────────────────────────
vim.lsp.config("nixd", {
  cmd       = { "nixd" },
  filetypes = { "nix" },
  root_markers = { "flake.nix", "default.nix", "shell.nix", ".git" },
})

-- ── Enable all servers ────────────────────────────────────────────────────────
vim.lsp.enable({
  "clangd",
  "pyright",
  "gopls",
  "lua_ls",
  "nixd",
})

-- ── LspAttach callbacks ───────────────────────────────────────────────────────
local lsp_group = vim.api.nvim_create_augroup("UserLsp", { clear = true })

-- Native completion
vim.api.nvim_create_autocmd("LspAttach", {
  group    = lsp_group,
  callback = function(event)
    local client = vim.lsp.get_client_by_id(event.data.client_id)
    if client and client:supports_method("textDocument/completion") then
      vim.lsp.completion.enable(true, client.id, event.buf, { autotrigger = true })
    end
  end,
})

-- Keymaps
vim.api.nvim_create_autocmd("LspAttach", {
  group    = lsp_group,
  callback = function(event)
    local map = function(keys, fn, desc)
      vim.keymap.set("n", keys, fn, { buffer = event.buf, silent = true, desc = desc })
    end

    -- Navigation
    map("gd",  vim.lsp.buf.definition,     "LSP: Go to definition")
    map("gD",  vim.lsp.buf.declaration,    "LSP: Go to declaration")
    map("gr",  vim.lsp.buf.references,     "LSP: References")
    map("gi",  vim.lsp.buf.implementation, "LSP: Implementation")
    map("K",   vim.lsp.buf.hover,          "LSP: Hover docs")

    -- Diagnostics
    map("[d",        vim.diagnostic.goto_prev,  "Diagnostic: previous")
    map("]d",        vim.diagnostic.goto_next,  "Diagnostic: next")
    map("<leader>e", vim.diagnostic.open_float, "Diagnostic: float")
    map("<leader>q", vim.diagnostic.setloclist, "Diagnostic: to loclist")

    -- Toggle diagnostics
    local diagnostics_enabled = true
    map("<leader>td", function()
      diagnostics_enabled = not diagnostics_enabled
      if diagnostics_enabled then
        vim.diagnostic.enable(event.buf)
      else
        vim.diagnostic.enable(false, { bufnr = event.buf })
      end
    end, "Diagnostic: toggle")

    -- Actions
    map("<leader>rn", vim.lsp.buf.rename,      "LSP: Rename")
    map("<leader>ca", vim.lsp.buf.code_action, "LSP: Code action")
    map("<leader>f",  function()
      vim.lsp.buf.format({ async = true })
    end, "LSP: Format file")

    -- Go: organize imports
    local client = vim.lsp.get_client_by_id(event.data.client_id)
    if client and client.name == "gopls" then
      map("<leader>oi", function()
        vim.lsp.buf.code_action({ context = { only = { "source.organizeImports" } }, apply = true })
      end, "Go: Organize imports")
    end
  end,
})
