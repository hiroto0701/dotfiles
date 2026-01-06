return {
  "ixru/nvim-markdown",
  ft = "markdown", -- Markdownファイルを開いた時のみ読み込み
  config = function()
    -- 設定
    vim.g.vim_markdown_folding_disabled = 0       -- 折りたたみを有効化（0で有効）
    vim.g.vim_markdown_folding_level = 6          -- 折りたたみレベル（1-6の見出しレベル）
    vim.g.vim_markdown_folding_style_pythonic = 1 -- Python風の折りたたみスタイル
    vim.g.vim_markdown_override_foldtext = 0      -- カスタム折りたたみテキストを使用

    -- フロントマター（YAML、TOML、JSON）のハイライト
    vim.g.vim_markdown_frontmatter = 1      -- YAML frontmatter
    vim.g.vim_markdown_toml_frontmatter = 1 -- TOML frontmatter
    vim.g.vim_markdown_json_frontmatter = 1 -- JSON frontmatter

    -- リンク
    vim.g.vim_markdown_follow_anchor = 1             -- アンカーリンクをたどる
    vim.g.vim_markdown_no_extensions_in_markdown = 0 -- .md拡張子を追加しない
    vim.g.vim_markdown_autowrite = 0                 -- リンクをたどる際に自動保存しない
    vim.g.vim_markdown_edit_url_in = "tab"           -- リンク先を新しいタブで開く

    -- シンタックスハイライト
    vim.g.vim_markdown_emphasis_multiline = 1  -- 複数行の強調を有効化
    vim.g.vim_markdown_conceal = 2             -- リンクとコードの非表示レベル（0-2）
    vim.g.vim_markdown_conceal_code_blocks = 0 -- コードブロックは隠さない
    vim.g.vim_markdown_math = 1                -- LaTeX数式のハイライト
    vim.g.vim_markdown_strikethrough = 1       -- 取り消し線のハイライト

    -- テーブル
    vim.g.vim_markdown_new_list_item_indent = 2 -- リストのインデント幅
    vim.g.vim_markdown_auto_insert_bullets = 1  -- 箇条書きの自動挿入
    vim.g.vim_markdown_new_list_item_indent = 0 -- 新しいリスト項目のインデント

    vim.api.nvim_create_autocmd("FileType", {
      pattern = "markdown",
      callback = function()
        local opts = { buffer = true, silent = true }

        -- 折りたたみ
        vim.keymap.set("n", "<Tab>", "za", vim.tbl_extend("force", opts, { desc = "折りたたみ切り替え" }))
        vim.keymap.set("n", "<S-Tab>", "zA", vim.tbl_extend("force", opts, { desc = "折りたたみ全切り替え" }))

        -- チェックボックストグル
        vim.keymap.set("n", "<C-c>", "<Plug>Markdown_Checkbox", vim.tbl_extend("force", opts, { desc = "チェックボックス切り替え" }))

        -- リンク作成（インサートモード・ビジュアルモード）
        vim.keymap.set({ "i", "v" }, "<C-k>", "<Plug>Markdown_CreateLink",
          vim.tbl_extend("force", opts, { desc = "リンク作成" }))

        -- リンクを開く
        vim.keymap.set("n", "<CR>", "<Plug>Markdown_FollowLink", vim.tbl_extend("force", opts, { desc = "リンクを開く" }))
      end,
    })
  end,
}
