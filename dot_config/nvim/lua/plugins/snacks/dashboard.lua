---@class snacks.dashboard.Config
return {
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
      { icon = " ", key = "e", desc = "New file", action = ":ene | startinsert" },
      { icon = "󰒲 ", key = "z", desc = "Lazy", action = ":Lazy" },
      { icon = " ", key = "d", desc = "Dotfiles", action = ":e ~/.local/share/chezmoi" },
      { icon = "󰱼 ", key = "f", desc = "Find Files", action = ":Telescope find_files" },
      { icon = "󰑓 ", key = "s", desc = "Restore Session", action = ":lua require('persistence').load()" },
      { icon = "󰅚 ", key = "q", desc = "Quit", action = ":qa" },
    },
  },
  sections = {
    { section = "header" },
    { title = "Recent Files", icon = " ", section = "recent_files", indent = 2, padding = 1 },
    { title = "Projects", icon = " ", section = "projects", indent = 2, padding = 1 },
    { title = "Keymaps", icon = " ", section = "keys", indent = 2, padding = 1 },
    { section = "startup" },
  },
}
