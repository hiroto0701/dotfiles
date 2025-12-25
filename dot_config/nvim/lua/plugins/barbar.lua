return {
  "romgrk/barbar.nvim",
  dependencies = {
    "lewis6991/gitsigns.nvim",
    "nvim-tree/nvim-web-devicons",
  },
  init = function()
    vim.g.barbar_auto_setup = false
  end,
  opts = {
    animation = true,
    auto_hide = false,
    tabpages = true,
    clickable = true,
    icons = {
      buffer_index = false,
      buffer_number = false,
      button = "×",
      filetype = {
        enabled = true,
      },
      separator = { left = "│", right = "" },
      modified = { button = "●" },
      pinned = { button = "󰐃", filename = true },
    },
    sidebar_filetypes = {
      ["neo-tree"] = { event = "BufWipeout", text = "", align = "center" },
    },
  },
  version = "^1.0.0",
}

