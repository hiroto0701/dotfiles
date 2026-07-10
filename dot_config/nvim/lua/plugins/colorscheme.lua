return {
  {
    "catppuccin/nvim",
    name = "catppuccin",
    opts = {
      flavour = "mocha",
      transparent_background = true,
      integrations = {
        gitsigns = true,
        mason = true,
        neotree = true,
        treesitter = true,
        native_lsp = {
          enabled = true,
        },
      },
    },
  },
  {
    "LazyVim/LazyVim",
    opts = {
      -- Neovim 0.12 同梱の colors/catppuccin.vim が存在すると lazy.nvim が
      -- プラグイン版をロードしないため、明示的にロードしてから適用する
      colorscheme = function()
        require("catppuccin")
        vim.cmd.colorscheme("catppuccin")
      end,
    },
  },
}
