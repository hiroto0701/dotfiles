-- 基本設定
vim.cmd("set expandtab")
vim.cmd("set tabstop=2")
vim.cmd("set softtabstop=2")
vim.cmd("set shiftwidth=2")

-- リーダーキーをスペースに設定
vim.g.mapleader= " "

-- バッファ（タブ）操作のキーマップ（barbar.nvim用）
vim.keymap.set("n", "<Tab>", "<Cmd>BufferNext<CR>", { silent = true, desc = "次のバッファへ" })
vim.keymap.set("n", "<S-Tab>", "<Cmd>BufferPrevious<CR>", { silent = true, desc = "前のバッファへ" })
vim.keymap.set("n", "<leader>x", "<Cmd>BufferClose<CR>", { silent = true, desc = "バッファを閉じる" })
vim.keymap.set("n", "<leader>X", "<Cmd>BufferClose!<CR>", { silent = true, desc = "バッファを強制的に閉じる" })
-- バッファの並び替え
vim.keymap.set("n", "<A-<>", "<Cmd>BufferMovePrevious<CR>", { silent = true, desc = "バッファを左に移動" })
vim.keymap.set("n", "<A->>", "<Cmd>BufferMoveNext<CR>", { silent = true, desc = "バッファを右に移動" })
-- バッファのピン留め
vim.keymap.set("n", "<leader>p", "<Cmd>BufferPin<CR>", { silent = true, desc = "バッファをピン留め" })
-- バッファピッカー（ジャンプモード）
vim.keymap.set("n", "<leader>b", "<Cmd>BufferPick<CR>", { silent = true, desc = "バッファを選択" })

-- Lazy.nvimのブートストラップ
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup("plugins")
