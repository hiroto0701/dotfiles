return {
  "kana/vim-operator-replace",
  event = "VeryLazy",
  dependencies = {
    "kana/vim-operator-user",
  },
  config = function()
    -- s でレジスタの内容で置換(substitute)
    vim.keymap.set({ "n", "x" }, "s", "<Plug>(operator-replace)", { silent = true })
  end,
}
