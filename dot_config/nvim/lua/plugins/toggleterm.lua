return {
  "akinsho/toggleterm.nvim",
  version = "*",
  config = function()
    require("toggleterm").setup({
      -- ターミナルのサイズ
      size = function(term)
        if term.direction == "horizontal" then
          return 15
        elseif term.direction == "vertical" then
          return vim.o.columns * 0.4
        end
      end,
      -- ターミナルを開くキーマップ
      open_mapping = [[<C-\>]],
      -- ターミナルの方向 (horizontal, vertical, float, tab)
      direction = "float",
      -- フロートウィンドウの設定
      float_opts = {
        border = "curved", -- single, double, shadow, curved
        width = function()
          return math.floor(vim.o.columns * 0.9)
        end,
        height = function()
          return math.floor(vim.o.lines * 0.9)
        end,
      },
      -- ターミナルの背景を暗くする
      shade_terminals = true,
      shading_factor = 2,
    })

    -- ターミナルモードでのキーマップ
    function _G.set_terminal_keymaps()
      local opts = { buffer = 0 }
      -- Escでノーマルモードに戻る
      vim.keymap.set("t", "<Esc>", [[<C-\><C-n>]], opts)
      -- Ctrl+hjklでウィンドウ移動
      vim.keymap.set("t", "<C-h>", [[<Cmd>wincmd h<CR>]], opts)
      vim.keymap.set("t", "<C-j>", [[<Cmd>wincmd j<CR>]], opts)
      vim.keymap.set("t", "<C-k>", [[<Cmd>wincmd k<CR>]], opts)
      vim.keymap.set("t", "<C-l>", [[<Cmd>wincmd l<CR>]], opts)
    end

    vim.cmd("autocmd! TermOpen term://*toggleterm#* lua set_terminal_keymaps()")
  end,
}
