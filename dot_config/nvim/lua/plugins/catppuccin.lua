return {
  "catppuccin/nvim",
  name = "catppuccin",
  priority = 1000,
  config = function()
    require("catppuccin").setup({
      transparent_background = true,
      integrations = {
        barbar = true,
        gitsigns = true,
        mason = true,
        neotree = true,
        treesitter = true,
        telescope = {
          enabled = true,
        },
        native_lsp = {
          enabled = true,
        },
      },
    })
    vim.cmd.colorscheme "catppuccin"
  end
}
