# Neovim 設定（LazyVim ベース）

[LazyVim](https://github.com/LazyVim/LazyVim) starter をベースに、旧自作設定（lazy.nvim ベース）から移植した構成。

## 構成

- `lazyvim.json` -- 有効化済み extras（typescript / biome / json / docker / prisma / markdown / prettier / eslint / chezmoi）
- `lua/config/options.lua` -- LazyVim デフォルトとの差分のみ（cursorlineopt 等）
- `lua/config/keymaps.lua` -- 旧環境から移植したキーマップ（`,` プレフィックスの Snacks Picker、bufferline 操作、`<C-p>`、`<leader>rn`）
- `lua/plugins/` -- 持ち込みプラグインと上書き設定
  - `colorscheme.lua` -- catppuccin mocha（透過）。Neovim 0.12 同梱 catppuccin にプラグイン版が遮られる問題への対処込み
  - `im-select.lua` -- IME 自動切り替え（macOS）
  - `auto-save.lua` / `nvim-hlslens.lua` / `nvim-scrollbar.lua` / `hlchunk.lua` / `treesj.lua` / `various-textobjs.lua` / `nvim-markdown.lua` / `toggleterm.lua`
  - `lsp.lua` -- extras 外の LSP（html / cssls）
- `lazy-lock.json` -- プラグインバージョン固定

## メモ

- 補完は blink.cmp、ファジーファインダーは Snacks Picker（telescope 不使用）
- `s` は flash.nvim。surround は未導入（必要なら `:LazyExtras` で coding.mini-surround）
- キーマップ一覧・学習資料: `~/Desktop/lazyvim-trial-cheatsheet.html` / `lazyvim-trial-curriculum.html`
