return {
  "shellRaining/hlchunk.nvim",
  event = { "BufReadPre", "BufNewFile" },
  config = function()
    require("hlchunk").setup({
      chunk = {
        enable = true,
        notify = true,
        priority = 15,
        style = {
          { fg = "#ffffff" },
          { fg = "#ffffff" },
        },
        use_treesitter = true,
        chars = {
          horizontal_line = "─",
          vertical_line = "│",
          left_top = "╭",
          left_bottom = "╰",
          right_arrow = ">",
        },
        textobject = "",
        max_file_size = 1024 * 1024,
        error_sign = true,
      },
      indent = {
        enable = true,
        priority = 10,
        style = {
          { fg = "#3b4261" },
        },
        chars = {
          "│",
        },
      },
      line_num = {
        style = "#806d9c",
      },
    })
  end,
}
