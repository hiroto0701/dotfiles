return {
  "nvim-neo-tree/neo-tree.nvim",
  branch = "v3.x",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-tree/nvim-web-devicons",
    "MunifTanjim/nui.nvim",
  },
  config = function()
    require("neo-tree").setup({
      close_if_last_window = true, -- 最後のウィンドウなら閉じる
      filesystem = {
        filtered_items = {
          visible = true, -- 隠しファイルを表示
          hide_dotfiles = false,
          hide_gitignored = false,
        },
        follow_current_file = {
          enabled = true, -- 現在のファイルを自動でフォーカス
        },
      },
      window = {
        width = 30,
        mappings = {
          ["<space>"] = "none", -- リーダーキーとの競合を防ぐ
        },
      },
    })

    -- キーマップ
    vim.keymap.set("n", "<leader>e", ":Neotree toggle<CR>", { desc = "Toggle Neo-tree" })
    vim.keymap.set("n", "<leader>o", ":Neotree focus<CR>", { desc = "Focus Neo-tree" })
  end,
}
