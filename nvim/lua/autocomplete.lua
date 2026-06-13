require("blink.cmp").setup({
  sources = {
    default = { "lsp", "buffer", "path", "snippets" },
  },
  keymap = { preset = "default" },
  completion = {
    keyword = { range = "full" },
    accept = { auto_brackets = { enabled = true } },
    menu = { auto_show = true },
  },
})
