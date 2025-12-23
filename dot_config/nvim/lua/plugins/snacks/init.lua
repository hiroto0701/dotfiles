return {
  "folke/snacks.nvim",
  priority = 1000,
  lazy = false,
  opts = {
    dashboard = require("plugins.snacks.dashboard"),
    notifier = { enabled = true },
    quickfile = { enabled = true },
    statuscolumn = { enabled = true },
    words = { enabled = true },
  },
  config = function(_, opts)
    require("snacks").setup(opts)

    -- Dashboard のハイライトを水色に設定
    local blue = "#89b4fa"
    vim.api.nvim_set_hl(0, "SnacksDashboardHeader", { fg = blue })
    vim.api.nvim_set_hl(0, "SnacksDashboardIcon", { fg = blue })
    vim.api.nvim_set_hl(0, "SnacksDashboardKey", { fg = blue })
    vim.api.nvim_set_hl(0, "SnacksDashboardTitle", { fg = blue })
    vim.api.nvim_set_hl(0, "SnacksDashboardDesc", { fg = blue })
    vim.api.nvim_set_hl(0, "SnacksDashboardFile", { fg = blue })
    vim.api.nvim_set_hl(0, "SnacksDashboardDir", { fg = blue })
    vim.api.nvim_set_hl(0, "SnacksDashboardFooter", { fg = "#a6e3a1" }) -- フッターは緑
  end,
}
