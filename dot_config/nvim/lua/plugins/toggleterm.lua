return {
  "akinsho/toggleterm.nvim",
  version = "*",
  config = function()
    require("toggleterm").setup({
      -- ターミナルのサイズ
      size = function(term)
        if term.direction == "horizontal" then
          return 15 -- 下部ターミナルの高さ
        elseif term.direction == "vertical" then
          return vim.o.columns * 0.4
        end
      end,
      -- ターミナルを開くキーマップ
      open_mapping = [[<C-\>]],
      direction = "horizontal",
      shade_terminals = true,
      shading_factor = 2,
      -- フロートウィンドウの設定（lazygit用）
      float_opts = {
        border = "curved",
        width = function()
          return math.floor(vim.o.columns * 0.9)
        end,
        height = function()
          return math.floor(vim.o.lines * 0.9)
        end,
      },
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

    -- lazygit用のカスタムターミナル (Snacksを使用するためコメントアウト)
    -- local Terminal = require("toggleterm.terminal").Terminal
    -- local lazygit = Terminal:new({
    --   cmd = "lazygit",
    --   dir = "git_dir",
    --   direction = "float",
    --   float_opts = {
    --     border = "curved",
    --   },
    --   on_open = function(term)
    --     vim.cmd("startinsert!")
    --   end,
    --   on_close = function(term)
    --     vim.cmd("startinsert!")
    --   end,
    -- })

    -- lazygitをトグルする関数
    -- function _G.lazygit_toggle()
    --   lazygit:toggle()
    -- end

    -- キーマップ: <leader>gg でlazygitを開く (Snacksで定義されているためコメントアウト)
    -- vim.keymap.set("n", "<leader>gg", "<cmd>lua lazygit_toggle()<CR>", { desc = "Lazygit" })

    -- 複数ターミナルのキーマップ
    vim.keymap.set("n", "<leader>t1", "<cmd>1ToggleTerm<CR>", { desc = "Terminal 1" })
    vim.keymap.set("n", "<leader>t2", "<cmd>2ToggleTerm<CR>", { desc = "Terminal 2" })
    vim.keymap.set("n", "<leader>t3", "<cmd>3ToggleTerm<CR>", { desc = "Terminal 3" })
    vim.keymap.set("n", "<leader>tt", "<cmd>ToggleTerm<CR>", { desc = "Toggle Terminal" })
  end,
}
