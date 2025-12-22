# Inagaki Dotfiles

このリポジトリは [chezmoi](https://www.chezmoi.io/) を使用して dotfiles を管理しています。

## 概要

この dotfiles には以下の設定が含まれています：

- **zinit**: Zsh プラグインマネージャー
- **Powerlevel10k**: Zsh テーマ
- **ghostty**: ターミナルエミュレーター
- **fzf**: ファジーファインダー（fd と組み合わせて使用）
- **Homebrew**: パッケージマネージャー（前提条件）

## 前提条件

- macOS（Homebrew が使用可能な環境）
- Git がインストールされていること
- GitHub への SSH 接続が設定されていること（SSH キーが GitHub アカウントに登録されている必要があります）

## セットアップ手順

### 1. Homebrew のインストール

Homebrew がインストールされていない場合は、以下のコマンドでインストールします：

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### 2. chezmoi のインストール

Homebrew を使用して chezmoi をインストールします：

```bash
brew install chezmoi
```

### 3. リポジトリのクローンと適用

chezmoi を使用してこのリポジトリをクローンし、設定を適用します（SSH 接続を使用）：

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

**注意**: GitHub への接続は SSH で行う前提です。SSH キーが設定されていない場合は、事前に設定してください。

### 4. 依存ツールのインストール

以下のツールを Homebrew でインストールします：

```bash
# fzf（ファジーファインダー）
brew install fzf

# fd（fzf と組み合わせて使用する高速な find コマンド）
brew install fd

# その他のツール（必要に応じて）
brew install pyenv
brew install volta
brew install nodebrew
```

### 5. fzf のセットアップ

fzf のキーバインドと補完機能を有効化します（既に `.zshrc` に設定済みですが、初回は手動で実行）：

```bash
$(brew --prefix)/opt/fzf/install
```

### 6. 新しいシェルセッションの開始

新しいターミナルウィンドウを開くか、以下のコマンドで設定を再読み込みします：

```bash
source ~/.zshrc
```

### 7. Powerlevel10k の設定（初回のみ）

初回起動時に Powerlevel10k の設定ウィザードが表示される場合があります。好みに応じて設定してください：

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
- **ghostty**: モダンなターミナルエミュレーター

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

Powerlevel10k の設定は `~/.p10k.zsh` に保存されます。このファイルも chezmoi で管理したい場合は：

```bash
chezmoi add ~/.p10k.zsh
```

### ghostty の設定

ghostty の設定ファイルは `~/.config/ghostty/config` として管理されています。編集する場合は：

```bash
chezmoi edit dot_config/ghostty/config
```

## よくある問題と解決方法

### SSH 接続が失敗する

GitHub への SSH 接続が設定されていない場合は、以下の手順で設定してください：

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

`.zshrc` には zinit の自動インストール機能が含まれていますが、手動でインストールする場合は：

```bash
mkdir -p "$HOME/.local/share/zinit"
git clone https://github.com/zdharma-continuum/zinit "$HOME/.local/share/zinit/zinit.git"
```

### fzf が動作しない

fzf が正しくインストールされているか確認：

```bash
which fzf
fzf --version
```

fzf のキーバインドが有効になっていない場合は、`.zshrc` を再読み込み：

```bash
source ~/.zshrc
```

### ghostty が見つからない

ghostty がインストールされていない場合は、Homebrew でインストール：

```bash
brew install ghostty
```
