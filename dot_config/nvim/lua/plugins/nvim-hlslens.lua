return {
  "kevinhwang91/nvim-hlslens",
  event = "VeryLazy",
  config = function()
    require("hlslens").setup({
      calm_down = true,
      nearest_only = false,
      nearest_float_when = "auto",
    })

    local opts = { noremap = true, silent = true }

    vim.keymap.set(
      "n",
      "n",
      [[<Cmd>execute('normal! ' . v:count1 . 'n')<CR><Cmd>lua require('hlslens').start()<CR>]],
      vim.tbl_extend("force", opts, { desc = "次の検索結果へ (hlslens)" })
    )

    vim.keymap.set(
      "n",
      "N",
      [[<Cmd>execute('normal! ' . v:count1 . 'N')<CR><Cmd>lua require('hlslens').start()<CR>]],
      vim.tbl_extend("force", opts, { desc = "前の検索結果へ (hlslens)" })
    )

    vim.keymap.set(
      "n",
      "*",
      [[*<Cmd>lua require('hlslens').start()<CR>]],
      vim.tbl_extend("force", opts, { desc = "カーソル下の単語を検索 (hlslens)" })
    )

    vim.keymap.set(
      "n",
      "#",
      [[#<Cmd>lua require('hlslens').start()<CR>]],
      vim.tbl_extend("force", opts, { desc = "カーソル下の単語を逆検索 (hlslens)" })
    )

    vim.keymap.set(
      "n",
      "g*",
      [[g*<Cmd>lua require('hlslens').start()<CR>]],
      vim.tbl_extend("force", opts, { desc = "カーソル下の単語を部分検索 (hlslens)" })
    )

    vim.keymap.set(
      "n",
      "g#",
      [[g#<Cmd>lua require('hlslens').start()<CR>]],
      vim.tbl_extend("force", opts, { desc = "カーソル下の単語を部分逆検索 (hlslens)" })
    )
  end,
}
