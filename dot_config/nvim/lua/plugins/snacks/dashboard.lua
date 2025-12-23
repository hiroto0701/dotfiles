return {
  enabled = true,
  width = 60,
  preset = {
    header = [[
███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗
████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║
██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║
██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║
██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║
╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝]],
    keys = {
      { icon = "󰈔", key = "e", desc = "New file", action = ":ene | startinsert" },
      { icon = "󰒲", key = "z", desc = "Lazy", action = ":Lazy" },
      { icon = "", key = "d", desc = "Dotfiles", action = ":e ~/.config/nvim/init.lua" },
      { icon = "󰈫", key = "f", desc = "Files", action = ":Telescope find_files" },
      { icon = "󰒮", key = "s", desc = "Restore Session", action = ":lua require('persistence').load()" },
      { icon = "󰅚", key = "q", desc = "Quit", action = ":qa" },
    },
  },
  sections = {
    -- ヘッダー（ASCIIアート）
    { section = "header" },
    
    -- Recent Files セクション
    {
      title = "Recent Files",
      icon = "󰈔 ",
      padding = 1,
    },
    {
      section = "recent_files",
      indent = 2,
      limit = 5,
      padding = 1,
    },

    -- Projects セクション (ghq連携)
    {
      title = "Projects",
      icon = "",
      padding = 1,
    },
    {
      section = "projects",
      indent = 2,
      limit = 5,
      padding = 1,
    },

    -- Keymaps セクション
    {
      title = "Keymaps",
      icon = "",
      padding = 1,
    },
    {
      section = "keys",
      indent = 2,
      padding = 1,
    },

    -- フッター (起動時間)
    { section = "startup" },
  },
}
