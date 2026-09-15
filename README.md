# Inagaki Dotfiles

macOS の設定、Homebrew、dotfiles を [nix-darwin](https://github.com/nix-darwin/nix-darwin) と
[home-manager](https://github.com/nix-community/home-manager) で宣言管理しています。

dotfiles の実体はこのリポジトリ（`~/dotfiles`）に 1 つだけあり、ホームディレクトリ側の
`~/.zshrc` や `~/.config/nvim` はそこを指す symlink です。リポジトリのファイルを編集すると、
そのまま実機に反映されます。「適用」という工程はありません。

## 概要

この dotfiles には以下の設定が含まれています

- **nix-darwin**: macOS の `defaults`（Dock、Finder、トラックパッド、キーボードなど）と Homebrew の formula / cask を宣言
- **home-manager**: dotfiles の symlink 配置
- **nix-homebrew**: Homebrew 本体のインストールとバージョン固定、tap の信頼設定
- **zinit**: Zsh プラグインマネージャー
- **Powerlevel10k**: Zsh テーマ
- **Neovim**: テキストエディタ（Lazy.nvim でプラグイン管理）
- **ghostty**: ターミナルエミュレーター
- **wezterm**: ターミナルエミュレーター
- **aerospace**: タイル型ウィンドウマネージャー（[キーバインド一覧](.config/aerospace/KEYBINDS.md)）
- **fzf**: ファジーファインダー（fd と組み合わせて使用）
- **zoxide**: スマートなディレクトリナビゲーション（`z` コマンドで頻繁に訪問したディレクトリへ素早く移動）
- **bat**: モダンな `cat` コマンドの代替ツール（fzf のプレビューで使用）
- **ghq**: Git リポジトリ管理ツール
- **gh**: GitHub CLI（GitHub の操作をコマンドラインから実行）
- **lsd**: モダンな `ls` コマンドの代替ツール
- **yazi**: ターミナルファイルマネージャー（[キーバインド一覧](docs/yazi-keybindings.md)）
- **lazygit**: Git の TUI クライアント

## リポジトリ構成

リポジトリのパスはホームディレクトリの鏡写しです。`~/dotfiles/.config/nvim` が `~/.config/nvim` になります。

```text
~/dotfiles/
├── .config/
│   ├── aerospace/                # ディレクトリ単位で symlink
│   ├── ghostty/
│   ├── nvim/                     # lazy-lock.json の更新もそのままここに落ちる
│   ├── wezterm/
│   ├── yazi/
│   ├── cmux/settings.json        # ファイル単位（隣にアプリがランタイムファイルを書くため）
│   ├── herdr/config.toml
│   └── orca/keybindings.json     # 配置先は ~/.orca/keybindings.json（Orca は XDG 非対応）
├── .claude/skills/               # Claude Code のスキル 2 つ
├── .local/bin/difit-cmux
├── Library/Application Support/lazygit/config.yml
├── .zshrc, .zprofile, .p10k.zsh
├── nix/
│   ├── flake.nix                 # ホスト一覧、home-manager と nix-homebrew の組み込み
│   ├── darwin/
│   │   ├── default.nix           # ホスト共通の土台
│   │   ├── defaults.nix          # macOS の system.defaults
│   │   └── homebrew.nix          # tap / formula / cask の宣言
│   └── home/
│       ├── default.nix
│       └── dotfiles.nix          # source と target の対応表
├── docs/
└── README.md
```

symlink の対応表は `nix/home/dotfiles.nix` にあります。どのファイルがどこに置かれるかはこのファイルを見れば分かります。

## 前提条件

- macOS（Apple Silicon）
- 管理者権限（`sudo` が使えること）

Homebrew も git も事前に入れる必要はありません。

## セットアップ手順（新しい Mac）

### 1. Determinate Nix をインストール

```bash
curl -fsSL https://install.determinate.systems/nix | sh -s -- install
```

完了後、新しいターミナルを開きます。

### 2. リポジトリを clone

```bash
nix run nixpkgs#git -- clone https://github.com/hiroto0701/dotfiles ~/dotfiles
```

配置先は `~/dotfiles` 固定です。symlink がこの絶対パスを指すため、別の場所には置けません。
public リポジトリなので鍵は不要です。SSH 鍵を入れた後で remote を `git@github.com:hiroto0701/dotfiles.git` に切り替えてください。

### 3. ホスト名を登録

ホスト名が `BNMAC00101` 以外なら、`nix/flake.nix` の `hosts` に 1 行足して `git add` します。

```nix
hosts = {
  BNMAC00101 = { user = "mac83009105"; };
  <ホスト名> = { user = "<ユーザー名>"; };
};
```

ホスト名は `scutil --get LocalHostName` で確認できます。flake は git 追跡ファイルしか見ないので `git add nix/flake.nix` を忘れないでください。

### 4. switch

```bash
sudo nix run nix-darwin/master#darwin-rebuild -- switch --flake ~/dotfiles/nix#<ホスト名>
```

この 1 回で Homebrew 本体、formula / cask、macOS の defaults、dotfiles の symlink が全て入ります。

初回は `/nix/var/nix/profiles/system` が作られないことがあります。`ls /nix/var/nix/profiles/` に `system` が無ければ次で世代 1 を作ってください。

```bash
sudo nix-env -p /nix/var/nix/profiles/system --set "$(readlink /run/current-system)"
```

### 5. ログアウト / ログイン

`defaults` の一部（Caps Lock での IME 切替、トラックパッドのジェスチャなど）はログイン後に確定します。

### 6. 初回起動での自動セットアップ

- 最初のシェル起動で zinit が自身を clone してプラグインを入れます
- 最初の `nvim` 起動で lazy.nvim がプラグインを入れます
- `ya pkg install` で yazi のプラグインを入れます

### 手作業で残るもの

- SSH 鍵
- TCC 権限（Accessibility、Input Monitoring）
- アプリのログイン
- cask 化していない GUI アプリ（Orca、Raycast、Logi Options+、Chrome、Cursor、Docker Desktop）
- nodebrew / volta / pyenv / mise で入れているランタイム

## 日常の運用

### 設定ファイルの編集

`~/.config/nvim/init.lua` でも `~/dotfiles/.config/nvim/init.lua` でも同じファイルです。編集したらコミットするだけです。

```bash
cd ~/dotfiles
git status
git add .config/nvim
git commit -m "chore(nvim): ..."
```

Neovim のプラグイン更新（`lazy-lock.json` の変更）は `.zshrc` の `nvim-sync` でコミットできます。

```bash
nvim-sync
```

### 宣言の変更（defaults / Homebrew / symlink の対応表）

`nix/` 配下を編集し、新規ファイルは `git add` してから switch します。

```bash
sudo darwin-rebuild switch --flake ~/dotfiles/nix
```

新しい設定ファイルを管理下に置くときは、リポジトリの鏡写し位置にファイルを置き、
`nix/home/dotfiles.nix` に 1 行足して switch します。既にホーム側に同じパスの実ファイルがある場合は
`<パス>.hm-backup` に退避されてから symlink が置かれます。中身を確認したら退避ファイルは消してください。

### 入力（nixpkgs / nix-darwin / home-manager / Homebrew 本体）の更新

```bash
nix flake update --flake ~/dotfiles/nix
sudo darwin-rebuild switch --flake ~/dotfiles/nix
```

Homebrew 本体のバージョンは `nix/flake.nix` の `brew-src` input（`github:Homebrew/brew/<バージョン>`）で固定しているため、`brew update` では上がりません。
上げるには `brew-src` の ref と `nix-homebrew.package` の `name` / `version` を新しいバージョンに変えてコミットし、switch します。
`brew --version` は版を表示しません（Homebrew の管理リポジトリが Nix 側にあるため）。入っている版は `readlink /opt/homebrew/Library/Homebrew` の store パス名で確認できます。

### ロールバック

```bash
sudo darwin-rebuild --rollback
```

戻るのは nix-darwin の activation（`/etc`、defaults の書き込み、`brew bundle` の実行）だけです。

- home-manager が置いた symlink は前の世代に戻しても残ります
- Homebrew の formula / cask は前の世代の宣言で `brew bundle` が走り、その宣言に合わせて増減します
- nix-homebrew による Homebrew 本体の管理も戻りません（Cellar / Caskroom は保たれます）

symlink を実ファイルに戻すには、退避ファイルが残っていれば次のように手で戻します。

```bash
rm ~/.zshrc
mv ~/.zshrc.hm-backup ~/.zshrc
```

退避ファイルを消した後なら、symlink を消してリポジトリからコピーします。

```bash
rm ~/.zshrc
cp ~/dotfiles/.zshrc ~/.zshrc
```

## 含まれているツールとプラグイン

### Zsh プラグイン（zinit 経由）

- **romkatv/powerlevel10k**: Zsh テーマ
- **zsh-users/zsh-autosuggestions**: コマンドの自動補完提案
- **reegnz/jq-zsh-plugin**: jq の補完機能
- **zsh-users/zsh-syntax-highlighting**: シンタックスハイライト
- **zsh-users/zsh-completions**: 追加の補完機能
- **zdharma/history-search-multi-word**: マルチワード履歴検索

### ghq のカスタム関数（`.zshrc`）

- **`cdrepo`**: fzf を使ってリポジトリを検索し、選択したリポジトリに移動します
- **`cursorrepo`**: fzf を使ってリポジトリを検索し、選択したリポジトリを Cursor で開きます
- **`nvimrepo`**: fzf を使ってリポジトリを検索し、選択したリポジトリを NeoVim で開きます

### lsd のエイリアス（`.zshrc`）

- **`ls`**: `lsd`
- **`l`**: `lsd -l`
- **`la`**: `lsd -a`
- **`lla`**: `lsd -la`
- **`lt`**: `lsd --tree`

### Neovim プラグイン（Lazy.nvim 経由）

- **catppuccin**: カラースキーム
- **alpha-nvim**: スタートアップ画面
- **neo-tree**: ファイルエクスプローラー
- **telescope**: ファジーファインダー
- **nvim-treesitter**: シンタックスハイライト
- **nvim-lspconfig**: LSP 設定
- **im-select.nvim**: IME 自動切り替え（ノーマルモード時に英語入力へ自動切替）

## よくある問題と解決方法

### `darwin-rebuild` が見つからない

初回 switch の前は `nix run nix-darwin/master#darwin-rebuild -- <サブコマンド>` を使います。
switch 後は `/run/current-system/sw/bin/darwin-rebuild` に入り、新しいシェルから `darwin-rebuild` で呼べます。

### switch で `Unexpected files in /etc` と出る

Nix のインストーラが書いた `/etc/zshrc` などが nix-darwin の既知ハッシュと一致しない場合に出ます。
表示されたファイルを `sudo mv /etc/zshrc /etc/zshrc.before-nix-darwin` のように退避して再実行します。

### zinit がインストールされない

`.zshrc` には zinit の自動インストール機能が含まれていますが、手動でインストールする場合は

```bash
mkdir -p "$HOME/.local/share/zinit"
git clone https://github.com/zdharma-continuum/zinit "$HOME/.local/share/zinit/zinit.git"
```

### SSH 接続が失敗する

```bash
ssh-keygen -t ed25519 -C "your_email@example.com"
cat ~/.ssh/id_ed25519.pub
```

表示された公開鍵を GitHub の Settings > SSH and GPG keys に追加し、`ssh -T git@github.com` で接続を確認します。
