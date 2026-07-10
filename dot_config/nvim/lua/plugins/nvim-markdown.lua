return {
  "ixru/nvim-markdown",
  ft = "markdown",
  config = function()
    vim.g.vim_markdown_folding_disabled = 0
    vim.g.vim_markdown_folding_level = 6
    vim.g.vim_markdown_folding_style_pythonic = 1
    vim.g.vim_markdown_override_foldtext = 0

    vim.g.vim_markdown_frontmatter = 1
    vim.g.vim_markdown_toml_frontmatter = 1
    vim.g.vim_markdown_json_frontmatter = 1

    vim.g.vim_markdown_follow_anchor = 1
    vim.g.vim_markdown_no_extensions_in_markdown = 0
    vim.g.vim_markdown_autowrite = 0
    vim.g.vim_markdown_edit_url_in = "tab"

    vim.g.vim_markdown_emphasis_multiline = 1
    vim.g.vim_markdown_conceal = 2
    vim.g.vim_markdown_conceal_code_blocks = 0
    vim.g.vim_markdown_math = 1
    vim.g.vim_markdown_strikethrough = 1

    vim.g.vim_markdown_new_list_item_indent = 2
    vim.g.vim_markdown_auto_insert_bullets = 1
    vim.g.vim_markdown_new_list_item_indent = 0

    vim.api.nvim_create_autocmd("FileType", {
      pattern = "markdown",
      callback = function()
        local opts = { buffer = true, silent = true }

        vim.keymap.set("n", "<Tab>", "za", vim.tbl_extend("force", opts, { desc = "折りたたみ切り替え" }))
        vim.keymap.set("n", "<S-Tab>", "zA", vim.tbl_extend("force", opts, { desc = "折りたたみ全切り替え" }))

        vim.keymap.set(
          "n",
          "<C-c>",
          "<Plug>Markdown_Checkbox",
          vim.tbl_extend("force", opts, { desc = "チェックボックス切り替え" })
        )

        vim.keymap.set(
          { "i", "v" },
          "<C-k>",
          "<Plug>Markdown_CreateLink",
          vim.tbl_extend("force", opts, { desc = "リンク作成" })
        )

        vim.keymap.set(
          "n",
          "<CR>",
          "<Plug>Markdown_FollowLink",
          vim.tbl_extend("force", opts, { desc = "リンクを開く" })
        )
      end,
    })
  end,
}
