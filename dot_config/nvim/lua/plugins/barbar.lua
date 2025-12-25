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
      diagnostics = {
        [vim.diagnostic.severity.ERROR] = { enabled = true, icon = "" },
        [vim.diagnostic.severity.WARN] = { enabled = true, icon = "" },
        [vim.diagnostic.severity.INFO] = { enabled = true, icon = "󰋽" },
        [vim.diagnostic.severity.HINT] = { enabled = true, icon = "󰌵" },
      },
      gitsigns = {
        added = { enabled = true, icon = "+" },
        changed = { enabled = true, icon = "~" },
        deleted = { enabled = true, icon = "-" },
      },
    },
    sidebar_filetypes = {
      ["neo-tree"] = { event = "BufWipeout", text = "", align = "center" },
    },
  },
  version = "^1.0.0",
}

