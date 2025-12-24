-- 基本設定
vim.cmd("set expandtab")
vim.cmd("set tabstop=2")
vim.cmd("set softtabstop=2")
vim.cmd("set shiftwidth=2")

-- リーダーキーをスペースに設定
vim.g.mapleader= " "

-- バッファ（タブ）操作のキーマップ
vim.keymap.set("n", "<Tab>", ":bnext<CR>", { silent = true, desc = "次のバッファへ" })
vim.keymap.set("n", "<S-Tab>", ":bprev<CR>", { silent = true, desc = "前のバッファへ" })
vim.keymap.set("n", "<leader>x", ":bd<CR>", { silent = true, desc = "バッファを閉じる" })
vim.keymap.set("n", "<leader>X", ":bd!<CR>", { silent = true, desc = "バッファを強制的に閉じる" })

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
