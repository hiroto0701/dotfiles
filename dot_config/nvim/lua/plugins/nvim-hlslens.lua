return {
  "kevinhwang91/nvim-hlslens",
  event = "VeryLazy", -- 遅延読み込み
  config = function()
    require("hlslens").setup({
      -- 検索ハイライトを自動的に有効化
      calm_down = true,
      -- 最も近いマッチにフォーカス
      nearest_only = false,
      -- 浮動ウィンドウの設定
      nearest_float_when = "auto",
    })

    -- キーマップ設定
    local opts = { noremap = true, silent = true }

    -- n と N のキーマップを hlslens に対応させる
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

    -- * と # も hlslens に対応させる
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

    -- g* と g# も対応
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

    -- ESC で検索ハイライトをクリア
    vim.keymap.set(
      "n",
      "<Esc>",
      "<Cmd>nohlsearch<CR><Esc>",
      vim.tbl_extend("force", opts, { desc = "検索ハイライトをクリア" })
    )
  end,
}
