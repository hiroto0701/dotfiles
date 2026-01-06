return {
  "MeanderingProgrammer/render-markdown.nvim",
  dependencies = {
    "nvim-treesitter/nvim-treesitter",
    "nvim-tree/nvim-web-devicons",
  },
  ft = "markdown", -- Markdownファイルを開いた時のみ読み込み
  opts = {
    -- ファイルタイプ
    file_types = { "markdown" },

    -- コードブロック
    code = {
      enabled = true,
      sign = true,
      style = "full",
      position = "left",
      width = "full",
      left_pad = 0,
      right_pad = 0,
      min_width = 0,
      border = "thin",
      above = "▄",
      below = "▀",
      highlight = "RenderMarkdownCode",
      highlight_inline = "RenderMarkdownCodeInline",
    },

    -- 見出し
    heading = {
      enabled = true,
      sign = true,
      position = "overlay",
      icons = { "󰲡 ", "󰲣 ", "󰲥 ", "󰲧 ", "󰲩 ", "󰲫 " },
      signs = { "󰫎 " },
      width = "full",
      left_pad = 0,
      right_pad = 0,
      min_width = 0,
      border = false,
      border_prefix = false,
      above = "▄",
      below = "▀",
      backgrounds = {
        "RenderMarkdownH1Bg",
        "RenderMarkdownH2Bg",
        "RenderMarkdownH3Bg",
        "RenderMarkdownH4Bg",
        "RenderMarkdownH5Bg",
        "RenderMarkdownH6Bg",
      },
      foregrounds = {
        "RenderMarkdownH1",
        "RenderMarkdownH2",
        "RenderMarkdownH3",
        "RenderMarkdownH4",
        "RenderMarkdownH5",
        "RenderMarkdownH6",
      },
    },

    -- チェックボックス
    checkbox = {
      enabled = true,
      unchecked = {
        icon = "󰄱 ",
        highlight = "RenderMarkdownUnchecked",
      },
      checked = {
        icon = "󰱒 ",
        highlight = "RenderMarkdownChecked",
      },
      custom = {
        todo = { raw = "[-]", rendered = "󰥔 ", highlight = "RenderMarkdownTodo" },
      },
    },

    -- 箇条書き
    bullet = {
      enabled = true,
      icons = { "●", "○", "◆", "◇" },
      left_pad = 0,
      right_pad = 0,
      highlight = "RenderMarkdownBullet",
    },

    -- 引用
    quote = {
      enabled = true,
      icon = "▎",
      highlight = "RenderMarkdownQuote",
    },

    -- テーブル
    pipe_table = {
      enabled = true,
      style = "full",
      cell = "padded",
      border = {
        "┌", "┬", "┐",
        "├", "┼", "┤",
        "└", "┴", "┘",
        "│", "─",
      },
      alignment_indicator = "━",
      head = "RenderMarkdownTableHead",
      row = "RenderMarkdownTableRow",
      filler = "RenderMarkdownTableFill",
    },

    -- リンク
    link = {
      enabled = true,
      image = "󰥶 ",
      hyperlink = "󰌹 ",
      highlight = "RenderMarkdownLink",
      custom = {},
    },

    -- インラインコード
    inline_code = {
      enabled = true,
      highlight = "RenderMarkdownCodeInline",
    },

    -- その他
    win_options = {
      conceallevel = {
        default = vim.api.nvim_get_option_value("conceallevel", {}),
        rendered = 3,
      },
      concealcursor = {
        default = vim.api.nvim_get_option_value("concealcursor", {}),
        rendered = "",
      },
    },
  },
  config = function(_, opts)
    require("render-markdown").setup(opts)
  end,
}
