# Inagaki Dotfiles

このリポジトリは [chezmoi](https://www.chezmoi.io/) を使用して dotfiles を管理しています。

## 概要

この dotfiles には以下の設定が含まれています

- **zinit**: Zsh プラグインマネージャー
- **Powerlevel10k**: Zsh テーマ
- **Neovim**: テキストエディタ（Lazy.nvim でプラグイン管理）
- **ghostty**: ターミナルエミュレーター
- **wezterm**: ターミナルエミュレーター
- **fzf**: ファジーファインダー（fd と組み合わせて使用）
- **bat**: モダンな `cat` コマンドの代替ツール（fzf のプレビューで使用）
- **ghq**: Git リポジトリ管理ツール
- **lsd**: モダンな `ls` コマンドの代替ツール
- **Homebrew**: パッケージマネージャー（前提条件）

## 前提条件

- macOS（Homebrew が使用可能な環境）
- Git がインストールされていること
- GitHub への SSH 接続が設定されていること（SSH キーが GitHub アカウントに登録されている必要があります）

## セットアップ手順

### 1. Homebrew のインストール

Homebrew がインストールされていない場合は、以下のコマンドでインストールします

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### 2. chezmoi のインストール

Homebrew を使用して chezmoi をインストールします

```bash
brew install chezmoi
```

### 3. リポジトリのクローンと適用

chezmoi を使用してこのリポジトリをクローンし、設定を適用します（SSH 接続を使用）

```bash
chezmoi init --apply git@github.com:hiroto0701/dotfiles.git
```

または、既存のリポジトリをローカルにクローンしている場合は、そのリポジトリのパスを指定します：

```bash
# 例: ホームディレクトリにクローンした場合
chezmoi init ~/dotfiles
chezmoi apply

# 例: 現在のディレクトリにクローンした場合
chezmoi init ./dotfiles
chezmoi apply

# 例: 絶対パスで指定する場合
chezmoi init /Users/username/dotfiles
chezmoi apply
```

**注意** GitHub への接続は SSH で行う前提です。SSH キーが設定されていない場合は、事前に設定してください

### 4. 依存ツールのインストール

以下のツールを Homebrew でインストールします

```bash
# fzf（ファジーファインダー）
brew install fzf

# fd（fzf と組み合わせて使用する高速な find コマンド）
brew install fd

# bat（モダンな cat コマンドの代替ツール、fzf のプレビューで使用）
brew install bat

# ghq（Git リポジトリ管理ツール）
brew install ghq

# lsd（モダンな ls コマンドの代替ツール）
brew install lsd

# neovim（テキストエディタ）
brew install neovim

# im-select（IME制御ツール）
brew tap daipeihust/tap
brew install im-select

# lazy-git（GUIでgit操作できるようにするツール）
brew install lazygit

# aerospace(window manager)
brew install --cask nikitabobko/tap/aerospace

# jankyborders(アクティブウィンドウを目立たせる)
brew tap FelixKratz/formulae
brew install borders

# alt-tab
brew install --cask alt-tab

# その他のツール（必要に応じて）
brew install pyenv
brew install volta
brew install nodebrew
```

### 5. fzf のセットアップ

fzf のキーバインドと補完機能を有効化します（既に `.zshrc` に設定済みですが、初回は手動で実行）

```bash
$(brew --prefix)/opt/fzf/install
```

**注意** fzf のプレビューには `bat` が使用されるように設定されています。ファイルを選択すると、bat でシンタックスハイライト付きでプレビューが表示されます

### 6. ghq の使い方

ghq は Git リポジトリを一元管理するツールです。以下のカスタム関数が `.zshrc` に定義されています

- **`cdrepo`**: fzf を使ってリポジトリを検索し、選択したリポジトリに移動します
- **`cursorrepo`**: fzf を使ってリポジトリを検索し、選択したリポジトリを Cursor で開きます
- **`nvimrepo`**: fzf を使ってリポジトリを検索し、選択したリポジトリを NeoVim で開きます

使用例

```bash
# リポジトリをクローン（ghq が自動的に管理）
ghq get https://github.com/user/repo.git

# リポジトリ一覧を表示
ghq list

# fzf でリポジトリを検索して移動
cdrepo

# fzf でリポジトリを検索して Cursor で開く
cursorrepo

# fzf でリポジトリを検索して NeoVim で開く
nvimrepo
```

### 7. lsd のエイリアス

lsd は `ls` コマンドのモダンな代替ツールで、以下のエイリアスが `.zshrc` に設定されています

- **`ls`**: `lsd` にエイリアスされています（デフォルトでカラー表示とアイコン表示）
- **`l`**: `lsd -l` - 詳細表示
- **`la`**: `lsd -a` - 隠しファイルを含む表示
- **`lla`**: `lsd -la` - 隠しファイルを含む詳細表示
- **`lt`**: `lsd --tree` - ツリー形式で表示

使用例

```bash
# 通常のリスト表示（カラーとアイコン付き）
ls

# 詳細表示
l

# 隠しファイルを含む表示
la

# 隠しファイルを含む詳細表示
lla

# ツリー形式で表示
lt
```

### 8. 新しいシェルセッションの開始

新しいターミナルウィンドウを開くか、以下のコマンドで設定を再読み込みします

```bash
source ~/.zshrc
```

### 9. Powerlevel10k の設定（初回のみ）

初回起動時に Powerlevel10k の設定ウィザードが表示される場合があります。好みに応じて設定してください

```bash
p10k configure
```

## 含まれているツールとプラグイン

### Zsh プラグイン（zinit 経由）

- **romkatv/powerlevel10k**: Zsh テーマ
- **zsh-users/zsh-autosuggestions**: コマンドの自動補完提案
- **reegnz/jq-zsh-plugin**: jq の補完機能
- **zsh-users/zsh-syntax-highlighting**: シンタックスハイライト
- **zsh-users/zsh-completions**: 追加の補完機能
- **zdharma/history-search-multi-word**: マルチワード履歴検索

### その他のツール

- **fzf**: ファジーファインダー（ファイル検索、履歴検索など）
- **fd**: 高速なファイル検索ツール（fzf と組み合わせて使用）
- **bat**: モダンな `cat` コマンドの代替ツール（シンタックスハイライト、fzf のプレビューで使用）
- **ghq**: Git リポジトリ管理ツール（fzf と組み合わせてリポジトリを検索・移動）
- **lsd**: モダンな `ls` コマンドの代替ツール（アイコン表示、カラー出力など）
- **neovim**: モダンなテキストエディタ（Lazy.nvim でプラグイン管理）
- **ghostty**: モダンなターミナルエミュレーター
- **wezterm**: クロスプラットフォームなターミナルエミュレーター

### Neovim プラグイン（Lazy.nvim 経由）

- **catppuccin**: カラースキーム
- **alpha-nvim**: スタートアップ画面
- **neo-tree**: ファイルエクスプローラー
- **telescope**: ファジーファインダー
- **nvim-treesitter**: シンタックスハイライト
- **nvim-lspconfig**: LSP 設定
- **im-select.nvim**: IME 自動切り替え（ノーマルモード時に英語入力へ自動切替）

## chezmoi チートシート

### 基本的な操作

```bash
# 設定ファイルを適用する
chezmoi apply

# 設定ファイルの状態を確認する
chezmoi status

# 設定ファイルの差分を確認する
chezmoi diff

# リモートリポジトリから最新の変更を取得して適用する
chezmoi update

# 管理されているファイルの一覧を表示する
chezmoi managed
```

### ファイルの追加・編集

```bash
# 新しいファイルを chezmoi で管理する
chezmoi add ~/.example

# 既存のファイルを編集する
chezmoi edit ~/.zshrc

# 特定のファイルを編集する（ファイル名のみでも可）
chezmoi edit dot_zshrc
```

### ファイルの削除

```bash
# ファイルを chezmoi の管理から外す（実際のファイルは削除されない）
chezmoi remove ~/.example

# ファイルを chezmoi の管理から外し、実際のファイルも削除する
chezmoi remove --force ~/.example
```

### 変更の確認とコミット

```bash
# 変更内容を確認する
chezmoi diff

# 変更をリポジトリにコミットする（chezmoi リポジトリ内で実行）
cd ~/.local/share/chezmoi
git add .
git commit -m "Update dotfiles"
git push
```

### その他の便利なコマンド

```bash
# 管理されているファイルのパスを表示する
chezmoi managed

# 特定のファイルが管理されているか確認する
chezmoi managed ~/.zshrc

# 設定ファイルを適用する前にプレビューする
chezmoi apply --dry-run

# 特定のファイルのみを適用する
chezmoi apply ~/.zshrc

# リモートリポジトリの URL を確認する
chezmoi source-path

# リモートリポジトリの URL を変更する（SSH 接続を使用）
chezmoi init git@github.com:YOUR_USERNAME/YOUR_REPO.git
```

### その他の便利なコマンド（続き）

```bash
# 設定ファイルを強制的に上書きする（注意して使用）
chezmoi apply --force

# 設定ファイルをバックアップしてから適用する
chezmoi apply --backup

# chezmoi の設定を確認する
chezmoi doctor
```

## カスタマイズ

### Powerlevel10k の設定

Powerlevel10k の設定は `~/.p10k.zsh` に保存されます。このファイルも chezmoi で管理したい場合

```bash
chezmoi add ~/.p10k.zsh
```

### ghostty の設定

ghostty の設定ファイルは `~/.config/ghostty/config` として管理されています。編集する場合は

```bash
chezmoi edit dot_config/ghostty/config
```

### wezterm の設定

wezterm の設定は `~/.config/wezterm/` として管理されています。設定ファイルの構成

```text
dot_config/wezterm/
├── wezterm.lua    # メインの設定ファイル（UI設定）
└── keybinds.lua   # キーバインド設定
```

編集する場合は

```bash
# UI設定を編集
chezmoi edit dot_config/wezterm/wezterm.lua

# キーバインド設定を編集
chezmoi edit dot_config/wezterm/keybinds.lua
```

**注意** `wezterm.lua` は `keybinds.lua` を自動的に読み込みます。設定を変更した後は、wezterm を再起動するか、`Ctrl+Shift+R` で設定をリロードしてください

### Neovim の設定

Neovim の設定は `~/.config/nvim/` として管理されています。設定ファイルの構成

```text
dot_config/nvim/
├── init.lua              # メインの設定ファイル
├── lazy-lock.json        # Lazy.nvim のロックファイル
├── lua/
│   └── plugins/          # プラグイン設定
│       ├── alpha.lua     # スタートアップ画面
│       ├── catppuccin.lua # カラースキーム
│       ├── im-select.lua # IME 自動切り替え
│       ├── lsp.lua       # LSP 設定
│       ├── neo-tree.lua  # ファイルエクスプローラー
│       ├── telescope.lua # ファジーファインダー
│       └── treesitter.lua # シンタックスハイライト
└── after/
    └── lsp/              # LSP サーバー固有の設定
        ├── cssls.lua
        ├── html.lua
        ├── jsonls.lua
        ├── lua_ls.lua
        └── ts_ls.lua
```

編集する場合は

```bash
# メインの設定ファイルを編集
chezmoi edit dot_config/nvim/init.lua

# プラグイン設定を編集
chezmoi edit dot_config/nvim/lua/plugins/lsp.lua
```

#### Neovim プラグインの追加手順

新しいプラグインを追加する際は、以下の手順に従ってください：

1. **プラグイン設定ファイルを作成**

   chezmoi リポジトリ内に新しいプラグイン設定ファイルを作成します：

   ```bash
   # 例: im-select.nvim を追加する場合
   vim ~/.local/share/chezmoi/dot_config/nvim/lua/plugins/im-select.lua
   ```

2. **chezmoi apply で設定を反映**

   ```bash
   chezmoi apply
   ```

3. **NeoVim を起動してプラグインをインストール**

   ```bash
   nvim
   ```

   NeoVim 内で以下を実行：

   ```vim
   :Lazy sync
   ```

   **重要** インストールが完了するまで待ってから NeoVim を終了してください

4. **lazy-lock.json を chezmoi に反映**

   ```bash
   chezmoi re-add ~/.config/nvim/lazy-lock.json
   ```

5. **変更をコミット**

   ```bash
   cd ~/.local/share/chezmoi
   git add .
   git commit -m "add: 新しいプラグイン名"
   git push origin main
   ```

#### 注意事項

- **`lazy-lock.json` の扱い** このファイルは NeoVim（Lazy.nvim）が自動更新するファイルです。`chezmoi apply` を実行すると、chezmoi リポジトリのバージョンで上書きされるため、NeoVim でプラグインを更新した後は必ず `chezmoi re-add ~/.config/nvim/lazy-lock.json` で同期してください

- **`chezmoi apply` と `chezmoi re-add` の違い**
  - `chezmoi apply` chezmoi リポジトリ → 実際のファイル（上書き）
  - `chezmoi re-add <file>` 実際のファイル → chezmoi リポジトリ（取り込み）

### ghq のカスタム関数

ghq と fzf を組み合わせたカスタム関数は `.zshrc` に定義されています。関数を追加・変更する場合は

```bash
chezmoi edit dot_zshrc
```

### lsd のエイリアス

lsd のエイリアスは `.zshrc` に定義されています。エイリアスを追加・変更する場合は

```bash
chezmoi edit dot_zshrc
```

## よくある問題と解決方法

### SSH 接続が失敗する

GitHub への SSH 接続が設定されていない場合は、以下の手順で設定してください

1. SSH キーを生成（まだ持っていない場合）

```bash
ssh-keygen -t ed25519 -C "your_email@example.com"
```

2. SSH キーを GitHub に登録

```bash
cat ~/.ssh/id_ed25519.pub
```

上記コマンドで表示された公開鍵を GitHub の Settings > SSH and GPG keys に追加してください。

3. 接続をテスト

```bash
ssh -T git@github.com
```

### zinit がインストールされない

`.zshrc` には zinit の自動インストール機能が含まれていますが、手動でインストールする場合は

```bash
mkdir -p "$HOME/.local/share/zinit"
git clone https://github.com/zdharma-continuum/zinit "$HOME/.local/share/zinit/zinit.git"
```

### fzf が動作しない

fzf が正しくインストールされているか確認

```bash
which fzf
fzf --version
```

fzf のキーバインドが有効になっていない場合は、`.zshrc` を再読み込み

```bash
source ~/.zshrc
```

### ghostty が見つからない

ghostty がインストールされていない場合は、Homebrew でインストール

```bash
brew install ghostty
```
