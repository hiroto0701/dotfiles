---@type LazySpec
return {
  "folke/snacks.nvim",
  priority = 1000,
  lazy = false,
  init = function()
    -- デバッグ用グローバル関数
    _G.dd = function(...)
      Snacks.debug.inspect(...)
    end
    _G.bt = function()
      Snacks.debug.backtrace()
    end
    vim.print = _G.dd

    -- ユーザーコマンド
    vim.api.nvim_create_user_command("Bdelete", function()
      Snacks.bufdelete()
    end, { nargs = 0 })
    vim.api.nvim_create_user_command("Bdeleteall", function()
      Snacks.bufdelete.all()
    end, { nargs = 0 })
    vim.api.nvim_create_user_command("Lazygit", function()
      Snacks.lazygit()
    end, { nargs = 0 })
  end,
  keys = {
    -- Picker [[
    {
      ",<cr>",
      function()
        Snacks.picker.picker_actions()
      end,
      desc = "Picker Actions",
    },
    {
      ",<space>",
      function()
        Snacks.picker.grep({
          hidden = true,
        })
      end,
      desc = "Grep",
    },
    {
      ",b",
      function()
        Snacks.picker.grep_buffers()
      end,
      desc = "Grep Buffers",
    },
    {
      ",s",
      function()
        Snacks.picker.grep_word()
      end,
      desc = "Grep String",
      mode = { "n", "x" },
    },
    {
      ",P",
      function()
        Snacks.picker.projects()
      end,
      desc = "Projects",
    },
    {
      ",B",
      function()
        Snacks.picker.buffers()
      end,
      desc = "Buffers",
    },
    {
      ",c",
      function()
        Snacks.picker.colorschemes()
      end,
      desc = "Colorscheme",
    },
    {
      ",f",
      function()
        Snacks.picker.files({
          hidden = true,
        })
      end,
      desc = "Find Files",
    },
    {
      ",g",
      function()
        Snacks.picker.git_branches()
      end,
      desc = "Git Branches",
    },
    {
      ",h",
      function()
        Snacks.picker.help()
      end,
      desc = "Help Pages",
    },
    {
      ",j",
      function()
        Snacks.picker.jumps()
      end,
      desc = "Jumplist",
    },
    {
      ",l",
      function()
        Snacks.picker.lazy()
      end,
      desc = "Lazy",
    },
    {
      ",m",
      function()
        Snacks.picker.marks()
      end,
      desc = "Marks",
    },
    {
      ",p",
      function()
        Snacks.picker.commands()
      end,
      desc = "Commands",
    },
    {
      ",q",
      function()
        Snacks.picker.qflist()
      end,
      desc = "Quickfix List",
    },
    {
      ",r",
      function()
        Snacks.picker.resume()
      end,
      desc = "Resume",
    },
    {
      ",t",
      function()
        Snacks.picker.todo_comments()
      end,
      desc = "TODO",
    },
    {
      ",i",
      function()
        Snacks.picker.icons()
      end,
      desc = "Icons",
    },
    {
      ",z",
      function()
        Snacks.picker.zoxide()
      end,
      desc = "Zoxide",
    },
    {
      ",d",
      function()
        Snacks.picker.diagnostics_buffer()
      end,
      desc = "Buffer Diagnostics",
    },
    {
      ",D",
      function()
        Snacks.picker.diagnostics()
      end,
      desc = "Diagnostics",
    },
    -- Picker ]]
    -- Dim [[
    {
      "<leader>d",
      function()
        if Snacks.dim.enabled then
          Snacks.dim.disable()
        else
          Snacks.dim.enable()
        end
      end,
      desc = "Toggle Dim",
    },
    -- Dim ]]
    -- Lazygit [[
    {
      "<leader>g",
      function()
        Snacks.lazygit()
      end,
      desc = "Lazygit",
    },
    {
      "<leader>gg",
      function()
        Snacks.lazygit()
      end,
      desc = "Lazygit",
    },
    {
      "<leader>gl",
      function()
        Snacks.lazygit.log()
      end,
      desc = "Lazygit Log",
    },
    {
      "<leader>gk",
      function()
        Snacks.lazygit.log_file()
      end,
      desc = "Lazygit Log File",
    },
    -- Lazygit ]]
    -- Zen [[
    {
      "<leader>z",
      function()
        Snacks.zen()
      end,
      desc = "Zen Mode",
    },
    -- Zen ]]
    -- Buffer [[
    {
      "<leader>bd",
      function()
        Snacks.bufdelete()
      end,
      desc = "Delete Buffer",
    },
    -- Buffer ]]
    -- Scratch [[
    {
      "<leader>.",
      function()
        Snacks.scratch()
      end,
      desc = "Toggle Scratch Buffer",
    },
    {
      "<leader>S",
      function()
        Snacks.scratch.select()
      end,
      desc = "Select Scratch Buffer",
    },
    -- Scratch ]]
    -- Notifier [[
    {
      "<leader>n",
      function()
        Snacks.notifier.show_history()
      end,
      desc = "Notification History",
    },
    {
      "<leader>un",
      function()
        Snacks.notifier.hide()
      end,
      desc = "Dismiss All Notifications",
    },
    -- Notifier ]]
    -- Terminal [[
    {
      "<c-/>",
      function()
        Snacks.terminal()
      end,
      desc = "Toggle Terminal",
    },
    -- Terminal ]]
    -- Words [[
    {
      "]]",
      function()
        Snacks.words.jump(vim.v.count1)
      end,
      desc = "Next Reference",
      mode = { "n", "t" },
    },
    {
      "[[",
      function()
        Snacks.words.jump(-vim.v.count1)
      end,
      desc = "Prev Reference",
      mode = { "n", "t" },
    },
    -- Words ]]
    -- Git [[
    {
      "<leader>gB",
      function()
        Snacks.gitbrowse()
      end,
      desc = "Git Browse",
      mode = { "n", "v" },
    },
    -- Git ]]
    -- Rename [[
    {
      "<leader>cR",
      function()
        Snacks.rename.rename_file()
      end,
      desc = "Rename File",
    },
    -- Rename ]]
  },
  ---@type snacks.Config
  opts = {
    -- UI
    input = { enabled = true },
    notifier = { enabled = true },
    statuscolumn = { enabled = true },
    indent = { enabled = true },
    scroll = { enabled = true },
    -- Picker
    picker = {
      enabled = true,
      ui_select = true,
      formatters = {
        file = {
          filename_first = true,
          truncate = 400,
        },
      },
    },
    -- Performance
    bigfile = { enabled = true },
    quickfile = { enabled = true },
    -- Development
    debug = { enabled = true },
    scratch = { enabled = true },
    -- Git
    lazygit = { enabled = true },
    gitbrowse = { enabled = true },
    -- Focus
    zen = { enabled = true },
    dim = { enabled = true },
    -- Navigation
    words = { enabled = true },
    -- Dashboard
    dashboard = require("plugins.snacks.dashboard"),
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
