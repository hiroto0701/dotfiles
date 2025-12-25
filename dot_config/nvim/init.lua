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
-- バッファの並び替え（Shift + h/l）
vim.keymap.set("n", "<S-h>", "<Cmd>BufferMovePrevious<CR>", { silent = true, desc = "バッファを左に移動" })
vim.keymap.set("n", "<S-l>", "<Cmd>BufferMoveNext<CR>", { silent = true, desc = "バッファを右に移動" })
-- バッファのピン留め
vim.keymap.set("n", "<leader>p", "<Cmd>BufferPin<CR>", { silent = true, desc = "バッファをピン留め" })
-- バッファピッカー（ジャンプモード）
vim.keymap.set("n", "<leader>b", "<Cmd>BufferPick<CR>", { silent = true, desc = "バッファを選択" })
-- 番号でバッファにジャンプ
vim.keymap.set("n", "<leader>1", "<Cmd>BufferGoto 1<CR>", { silent = true, desc = "バッファ1へ" })
vim.keymap.set("n", "<leader>2", "<Cmd>BufferGoto 2<CR>", { silent = true, desc = "バッファ2へ" })
vim.keymap.set("n", "<leader>3", "<Cmd>BufferGoto 3<CR>", { silent = true, desc = "バッファ3へ" })
vim.keymap.set("n", "<leader>4", "<Cmd>BufferGoto 4<CR>", { silent = true, desc = "バッファ4へ" })
vim.keymap.set("n", "<leader>5", "<Cmd>BufferGoto 5<CR>", { silent = true, desc = "バッファ5へ" })
vim.keymap.set("n", "<leader>6", "<Cmd>BufferGoto 6<CR>", { silent = true, desc = "バッファ6へ" })
vim.keymap.set("n", "<leader>7", "<Cmd>BufferGoto 7<CR>", { silent = true, desc = "バッファ7へ" })
vim.keymap.set("n", "<leader>8", "<Cmd>BufferGoto 8<CR>", { silent = true, desc = "バッファ8へ" })
vim.keymap.set("n", "<leader>9", "<Cmd>BufferGoto 9<CR>", { silent = true, desc = "バッファ9へ" })
vim.keymap.set("n", "<leader>0", "<Cmd>BufferLast<CR>", { silent = true, desc = "最後のバッファへ" })

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
