return {
  "goolord/alpha-nvim",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  config = function()
    local alpha = require("alpha")
    local dashboard = require("alpha.themes.dashboard")

    -- ヘッダー（ASCII アート）
    dashboard.section.header.val = {
      "                                                     ",
      "  ███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗ ",
      "  ████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║ ",
      "  ██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║ ",
      "  ██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║ ",
      "  ██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║ ",
      "  ╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝ ",
      "                                                     ",
    }

    -- ボタンのハイライト設定
    local function button(sc, txt, keybind, keybind_opts)
      local b = dashboard.button(sc, txt, keybind, keybind_opts)
      b.opts.hl = "AlphaButtons"
      b.opts.hl_shortcut = "AlphaShortcut"
      return b
    end

    -- セクションタイトル
    local function section_title(title)
      return {
        type = "text",
        val = title,
        opts = {
          position = "center",
          hl = "AlphaHeader",
        },
      }
    end

    -- メニューボタン（アイコン付き）
    dashboard.section.buttons.val = {
      section_title("  Recent Files"),
      { type = "padding", val = 1 },
      button("r", "󰈔  Recent Files", ":Telescope oldfiles<CR>"),
      { type = "padding", val = 1 },

      section_title("  Actions"),
      { type = "padding", val = 1 },
      button("f", "󰈞  Find File", ":Telescope find_files<CR>"),
      button("n", "󰈔  New File", ":ene <BAR> startinsert<CR>"),
      button("g", "󰊄  Find Text", ":Telescope live_grep<CR>"),
      button("b", "󰨞  Buffers", ":Telescope buffers<CR>"),
      { type = "padding", val = 1 },

      section_title("  Config"),
      { type = "padding", val = 1 },
      button("c", "  Configuration", ":e ~/.config/nvim/init.lua<CR>"),
      button("l", "󰒲  Lazy (Plugins)", ":Lazy<CR>"),
      button("q", "󰅙  Quit", ":qa<CR>"),
    }

    -- フッター（プラグイン数と起動時間を動的に表示）
    dashboard.section.footer.val = function()
      local stats = require("lazy").stats()
      local ms = (math.floor(stats.startuptime * 100 + 0.5) / 100)
      return "⚡ Neovim loaded " .. stats.loaded .. "/" .. stats.count .. " plugins in " .. ms .. "ms"
    end

    -- ハイライトグループの設定
    dashboard.section.header.opts.hl = "AlphaHeader"
    dashboard.section.footer.opts.hl = "AlphaFooter"

    -- レイアウト設定
    dashboard.config.layout = {
      { type = "padding", val = 2 },
      dashboard.section.header,
      { type = "padding", val = 2 },
      dashboard.section.buttons,
      { type = "padding", val = 2 },
      dashboard.section.footer,
    }

    alpha.setup(dashboard.config)

    -- ハイライトカラーの設定
    vim.api.nvim_set_hl(0, "AlphaHeader", { fg = "#89b4fa" })
    vim.api.nvim_set_hl(0, "AlphaButtons", { fg = "#cdd6f4" })
    vim.api.nvim_set_hl(0, "AlphaShortcut", { fg = "#f9e2af" })
    vim.api.nvim_set_hl(0, "AlphaFooter", { fg = "#a6e3a1" })
  end,
}
