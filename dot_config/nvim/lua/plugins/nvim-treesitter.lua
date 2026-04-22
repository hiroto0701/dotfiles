return {
  "nvim-treesitter/nvim-treesitter",
  branch = "main",
  build = ":TSUpdate",
  lazy = false,
  config = function()
    -- mainブランチではsetup()はinstall_dirのみ受け付ける
    -- ハイライト・インデントはNeovimビルトインのvim.treesitterが処理
    require("nvim-treesitter").setup()

    -- 使用するパーサーをインストール（非同期）
    require("nvim-treesitter.install").install({
      "lua",
      "vim",
      "vimdoc",
      "html",
      "css",
      "javascript",
      "typescript",
      "tsx",
      "json",
      "markdown",
      "markdown_inline",
    })

    -- ts_context_commentstring の設定
    require("ts_context_commentstring").setup({
      enable_autocmd = false,
    })
  end,
}
