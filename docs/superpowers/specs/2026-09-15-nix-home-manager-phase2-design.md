# nix Phase 2 設計: home-manager で dotfiles を移行し chezmoi を退役する

作成日: 2026-09-15
対象マシン: BNMAC00101 (macOS 26.1, Apple Silicon, ユーザー `mac83009105`)
前提: Phase 1（`docs/superpowers/specs/2026-09-14-nix-darwin-phase1-design.md`）完了済み。世代 4 が current
状態: 設計承認済み。実装プランは別ファイル（`docs/superpowers/plans/`）
参考にした構成: mozumasu/dotfiles（`.config/nix/home-manager/dotfiles.nix` の `mkOutOfStoreSymlink` 方式）

## 1. 背景と目的

Phase 1 で macOS 設定と Homebrew は nix-darwin で宣言化できたが、dotfiles は chezmoi のままで次の不満が残っている。

- `chezmoi apply` を忘れて、ソースと実機がずれる（実際に `~/.config/herdr/config.toml` が `MM` のまま）
- 別 PC で再現するとき、Homebrew と chezmoi の両方を先に手で入れる必要がある
- ソースのファイル名が `dot_config/` `private_dot_claude/` `executable_` のように chezmoi の命名になっていて、
  リポジトリを直接編集しても実機に反映されない

Phase 2 では home-manager を nix-darwin に組み込み、dotfiles を **リポジトリを直接指す symlink** に置き換える。
ファイルの実体はリポジトリに 1 つだけになり、「apply」という工程そのものが無くなる。
chezmoi は退役し、新 PC の手作業は「Nix をインストール → clone → `darwin-rebuild switch`」の 3 つになる。

### 段階計画における位置

| Phase | 内容 | 状態 |
|---|---|---|
| 1 | nix-darwin で `system.defaults` + `homebrew` を宣言化 | 完了（2026-09-15） |
| 2 | home-manager で dotfiles を symlink 化、リポジトリを `~/dotfiles` に再編、chezmoi 退役、nix-homebrew で brew 本体も宣言化 | **本設計** |
| 3 | brew formula を `home.packages`（nixpkgs）へ、nodebrew / volta / pyenv を mise または devShell へ | 未着手 |

Phase 2 と 3 を分ける理由: Phase 2 で壊れるのは「設定ファイルの参照」、Phase 3 で壊れるのは「コマンドの PATH とバージョン」で、
失敗時の切り戻し単位が違う。同時にやると原因の切り分けが難しくなる。

## 2. スコープ

### 含む

- home-manager を nix-darwin モジュールとして導入（standalone の `home-manager` コマンドは入れない）
- chezmoi 管理下の全 55 ファイルと、未管理だった `~/.zprofile` `~/.p10k.zsh` を `mkOutOfStoreSymlink` で symlink 化
- リポジトリを `~/.local/share/chezmoi` から `~/dotfiles` に移動し、chezmoi 命名（`dot_` `private_` `executable_` `readonly_`）を外して
  ターゲットパスの鏡写しにする
- nix-homebrew の導入（Homebrew 本体の宣言化、既存インストールの `autoMigrate`、tap の trust 宣言）
- chezmoi の退役（formula の削除、`.chezmoiignore` と `~/.config/chezmoi/` の削除）
- `.zshrc` の `nvim-sync` 関数から chezmoi 依存を外す（この 1 箇所のみ）
- README を新 PC 手順に書き直す

### 含まない

- `home.packages` によるパッケージ導入（Phase 3）
- `.zshrc` の中身の整理、`programs.zsh` への移行、zinit の置き換え
- `defaults.nix` `homebrew.nix` の宣言内容の変更（`chezmoi` を brews から外す 1 行を除く）
- `hosts` マップの構造変更、hostSpec のような抽象化
- nix-homebrew の宣言的 tap 管理（`mutableTaps = false`）。tap は Phase 1 の `homebrew.taps` のまま
- Orca / Raycast / Chrome など cask 化していない GUI アプリ
- SSH 鍵、TCC 権限、アプリのログイン
- `.claude/skills/` の 2 つ以外の Claude Code 設定

## 3. 決定事項

| 論点 | 決定 | 理由 |
|---|---|---|
| リポジトリの置き場所 | `~/dotfiles` | `mkOutOfStoreSymlink` はストア外の絶対パスを直指すため全マシンで同じパスに固定する必要がある。短く、ghq の設定に依存しない。mozumasu 氏と同じ |
| リポジトリのレイアウト | ターゲットパスの鏡写しをルートに置く（`~/dotfiles/.config/nvim` 等）。`nix/` `docs/` `README.md` はルートに同居 | Phase 1 の「`nix/` はルート」を維持。`dotfiles.nix` の対応表を見れば source と target の関係が分かる |
| 鏡写しの例外 | Orca の設定は source を `.config/orca/keybindings.json`、target を `~/.orca/keybindings.json` にする | Orca はアプリ内で `join(HOME, ".orca", "keybindings.json")` と固定で組んでおり XDG 非対応（§8.3）。読み先は動かせないが置き場所は `.config` に揃えたい（ユーザー要望） |
| home-manager の組み込み方 | `home-manager.darwinModules.home-manager` を `darwinSystem` の modules に追加 | `darwin-rebuild switch` 1 回で defaults → brew → dotfiles まで流れる。運用コマンドが増えない |
| `backupFileExtension` | `"hm-backup"` を設定する | 設定しないと、既存の実ファイルと内容が同一な場合 HM は「identical なのでスキップ」して symlink に置き換えない（§8.1）。chezmoi が置いた実ファイルは全て同一内容なので、これが無いと移行が空振りする |
| zsh の扱い | `programs.zsh` は有効化しない。`.zshrc` `.zprofile` `.p10k.zsh` を `home.file` でリンクするだけ | 中身を Nix に書き直す量が大きく、zinit との役割重複の整理も要る。Phase 3 で PATH 行を直すときも普通のファイル編集で済む |
| symlink の粒度 | アプリがランタイムファイルを隣に書くものは file 単位、書かないものは dir 単位 | dir 単位なら `lazy-lock.json` のような実行時更新がそのままリポジトリに落ちる。file 単位はログやソケットをリポジトリに巻き込まないため |
| Homebrew 本体 | nix-homebrew に任せる。このマシンは `autoMigrate = true` で引き継ぐ | 新 PC の手作業が 1 つ減る。Phase 1 の「brew は事前に入っている前提」は、Phase 2 の目的（ブートストラップ最小化）に合わせて改める |
| tap の信頼 | `nix-homebrew.trust.taps` に Phase 1 の 5 tap を宣言 | Phase 1 で手動実行した `brew trust --tap` を宣言化する（§8.4） |
| `home.stateVersion` | `"26.11"` | 新規導入なので現行最大値。home-manager の `modules/misc/version.nix` で確認 |
| chezmoi.toml の API キー | 移行しない。`~/.config/chezmoi/` ごと削除 | テンプレートが 0 なので参照されていない。値を別で残したいなら削除前に控える |

## 4. 構成

### 4.1 ディレクトリ

```
~/dotfiles/                                # 旧 ~/.local/share/chezmoi。git リポジトリ root
├── .config/
│   ├── aerospace/                         # 旧 dot_config/aerospace/
│   ├── cmux/settings.json
│   ├── ghostty/
│   ├── herdr/config.toml
│   ├── nvim/                              # dot_gitignore → .gitignore、dot_neoconf.json → .neoconf.json
│   ├── orca/keybindings.json              # 旧 dot_orca/。target は ~/.orca/
│   ├── wezterm/
│   └── yazi/                              # plugins/*/readonly_* の接頭辞を外す
├── .claude/skills/{grill-with-docs,llm-wiki}/   # 旧 private_dot_claude/
├── .local/bin/difit-cmux                  # 旧 executable_difit-cmux。git 上で 100755 にする
├── Library/Application Support/lazygit/config.yml   # 旧 private_Library/private_Application Support/
├── .zshrc                                 # 旧 dot_zshrc
├── .zprofile                              # 新規取り込み（brew shellenv 1 行）
├── .p10k.zsh                              # 新規取り込み（94 KB）
├── .envrc                                 # 既存。移動後に direnv allow が必要
├── nix/
│   ├── flake.nix                          # home-manager と nix-homebrew を追加
│   ├── flake.lock
│   ├── darwin/{default,defaults,homebrew}.nix   # homebrew.nix から chezmoi を外す
│   └── home/
│       ├── default.nix
│       └── dotfiles.nix                   # symlink の対応表
├── docs/superpowers/{specs,plans}/        # git 管理外（.gitignore）。public リポジトリに個人環境の詳細を出さない
├── .gitignore                             # docs/superpowers/
└── README.md                              # 新 PC 手順に書き直す
```

削除するもの: `.chezmoiignore`（nix / docs / README.md を配置対象から外す目的だったが、chezmoi が無くなれば不要）。

### 4.2 `nix/flake.nix`

```nix
{
  description = "nix-darwin configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:nix-darwin/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nix-homebrew.url = "github:zhaofengli/nix-homebrew";
  };

  outputs = { self, nix-darwin, nixpkgs, home-manager, nix-homebrew }:
    let
      hosts = {
        BNMAC00101 = { user = "mac83009105"; };
      };
    in {
      darwinConfigurations = builtins.mapAttrs (hostname: h:
        nix-darwin.lib.darwinSystem {
          modules = [
            ./darwin
            home-manager.darwinModules.home-manager
            nix-homebrew.darwinModules.nix-homebrew
            {
              # home-manager は home.homeDirectory をここから取る。未設定だと評価エラー
              users.users.${h.user}.home = "/Users/${h.user}";

              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                # 既存の実ファイルを <path>.hm-backup に退避してから symlink を置く。
                # 無いと内容が同一のファイルは symlink 化されない
                backupFileExtension = "hm-backup";
                users.${h.user} = import ./home;
              };

              nix-homebrew = {
                enable = true;
                user = h.user;
                autoMigrate = true;      # 公式スクリプトで入れた既存 /opt/homebrew を引き継ぐ
                mutableTaps = true;      # tap の追加削除は nix-darwin の homebrew.taps に任せる
                trust.taps = [
                  "daipeihust/tap"
                  "felixkratz/formulae"
                  "jesseduffield/lazydocker"
                  "nikitabobko/tap"
                  "oven-sh/bun"
                ];
              };
            }
          ];
          specialArgs = { inherit self hostname; username = h.user; };
        }) hosts;
    };
}
```

- `users.users.<name>` に `home` を書いても、`users.knownUsers` に載せない限り nix-darwin はそのユーザーを作成・変更しない。
  home-manager がホームディレクトリを読むためだけの宣言
- `useGlobalPkgs = true` は darwin 側の `nixpkgs.*`（`hostPlatform`）を home-manager と共有する。
  `useUserPackages = true` は Phase 3 の `home.packages` を `/etc/profiles/per-user/<user>` に置くための先行設定で、Phase 2 では中身が無い
- `enableRosetta` は既定（無効）のまま。Intel 版 brew は使っていない

### 4.3 `nix/home/default.nix`

```nix
{ ... }:
{
  imports = [ ./dotfiles.nix ];

  home.stateVersion = "26.11";
}
```

`home.username` と `home.homeDirectory` は nix-darwin モジュールが `users.users.<name>` から埋めるので書かない。

### 4.4 `nix/home/dotfiles.nix`

```nix
{ config, ... }:
let
  dotfiles = "${config.home.homeDirectory}/dotfiles";
  link = path: config.lib.file.mkOutOfStoreSymlink "${dotfiles}/${path}";
in
{
  # ~/.config/ 配下
  xdg.configFile = {
    # dir 単位: 実行時に書き換わる lazy-lock.json がそのままリポジトリに落ちる
    "nvim".source = link ".config/nvim";
    "aerospace".source = link ".config/aerospace";
    "ghostty".source = link ".config/ghostty";
    "wezterm".source = link ".config/wezterm";
    # dir 単位。plugins/git.yazi は switch 後に `ya pkg install` で再取得してコミットする
    "yazi".source = link ".config/yazi";
    # file 単位: cmux は cmux.json、herdr はログ・ソケット・session.json を隣に書く
    "cmux/settings.json".source = link ".config/cmux/settings.json";
    "herdr/config.toml".source = link ".config/herdr/config.toml";
  };

  # ~/ 配下
  home.file = {
    ".zshrc".source = link ".zshrc";
    ".zprofile".source = link ".zprofile";
    ".p10k.zsh".source = link ".p10k.zsh";
    # Orca は ~/.orca/keybindings.json 固定（XDG 非対応）。source だけ .config に寄せる。
    # ~/.orca/agent-hooks/ はランタイムなので file 単位
    ".orca/keybindings.json".source = link ".config/orca/keybindings.json";
    # ~/.claude/ 自体はランタイム。スキル 2 つだけ dir 単位で置く
    ".claude/skills/grill-with-docs".source = link ".claude/skills/grill-with-docs";
    ".claude/skills/llm-wiki".source = link ".claude/skills/llm-wiki";
    # 実行ビットは symlink 先（リポジトリ側）の mode で決まる。git 上で 100755 にしておく
    ".local/bin/difit-cmux".source = link ".local/bin/difit-cmux";
    # lazygit は state.yml を隣に書く
    "Library/Application Support/lazygit/config.yml".source = link "Library/Application Support/lazygit/config.yml";
  };
}
```

対応表（source は `~/dotfiles/` 相対、target は `~/` 相対）:

| source | target | 粒度 | ランタイム書き込み |
|---|---|---|---|
| `.config/nvim` | `.config/nvim` | dir | `lazy-lock.json`（リポジトリに落としたい） |
| `.config/aerospace` `.config/ghostty` `.config/wezterm` | 同名 | dir | 無し（`chezmoi unmanaged` で確認） |
| `.config/yazi` | `.config/yazi` | dir | `plugins/git.yazi`（未コミット。他 2 プラグインと同様にコミットする） |
| `.config/cmux/settings.json` | 同名 | file | `cmux.json` |
| `.config/herdr/config.toml` | 同名 | file | `.plugins.lock` `*.log` `herdr.sock` `session.json` `release-notes.json` |
| `.config/orca/keybindings.json` | `.orca/keybindings.json` | file | `agent-hooks/` |
| `.claude/skills/grill-with-docs` `.claude/skills/llm-wiki` | 同名 | dir | 無し。`~/.claude/skills/terminal-browser` が既に symlink で動いている |
| `.local/bin/difit-cmux` | 同名 | file | 無し |
| `Library/Application Support/lazygit/config.yml` | 同名 | file | `state.yml` |
| `.zshrc` `.zprofile` `.p10k.zsh` | 同名 | file | 無し |

symlink の連鎖は `~/.config/nvim` → `/nix/store/…-home-manager-files/.config/nvim` → `/nix/store/…-nvim`（`ln -s` 1 本の派生物）→ `~/dotfiles/.config/nvim`。
`readlink -f` で最終的にリポジトリのパスに解決される。

### 4.5 `nix/darwin/homebrew.nix` の変更

brews から `"chezmoi"` を外す。`onActivation.cleanup = "uninstall"` により switch で削除される。他は無変更。

### 4.6 `.zshrc` の `nvim-sync` の変更

現在は `chezmoi source-path` と `chezmoi add` に依存している。symlink 化後は `~/.config/nvim` の変更がそのままリポジトリの変更なので、
コミットだけに縮む。

```zsh
# nvim設定の変更をコミット（~/.config/nvim は ~/dotfiles/.config/nvim への symlink）
nvim-sync() {
  local repo="$HOME/dotfiles"
  local changed=$(git -C "$repo" status --porcelain -- .config/nvim)
  if [ -z "$changed" ]; then
    echo "変更なし"
    return 0
  fi
  git -C "$repo" add -- .config/nvim
  local msg="chore(nvim): 設定変更をコミット"
  if [ "$(echo "$changed" | awk '{print $2}' | sort -u)" = ".config/nvim/lazy-lock.json" ]; then
    msg="chore(nvim): プラグインロックを更新"
  fi
  git -C "$repo" commit -q -m "$msg" -- .config/nvim && git -C "$repo" log --oneline -1
}
```

`.zshrc` はリンク先がリポジトリなので、この編集は保存した瞬間に実機へ反映される。Phase 2 で `.zshrc` に触るのはここだけ。

### 4.7 README

chezmoi 前提の「セットアップ手順」を §6 の内容に置き換える。ツール一覧は残す。

## 5. 移行手順（このマシン）

各ステップでコミットする。手順 5 までは `~/.local/share/chezmoi` の git リポジトリを操作し、手順 6 で移動する。

| # | 作業 | 確認 |
|---|---|---|
| 1 | 準備。未コミットの `dot_config/ghostty/config`（keybind 追加）と `dot_orca/` をコミット。herdr の drift は実機側（`[experimental] kitty_graphics = true` あり）を正として `chezmoi add ~/.config/herdr/config.toml`。`chezmoi add ~/.zprofile ~/.p10k.zsh` で新規取り込み | `chezmoi status` が空、`git status` がクリーン |
| 2 | リポジトリ再編。`git mv` で `dot_config` → `.config`、`private_dot_claude` → `.claude`、`private_Library/private_Application Support` → `Library/Application Support`、`dot_local/bin/executable_difit-cmux` → `.local/bin/difit-cmux`（`git update-index --chmod=+x`）、`dot_orca/keybindings.json` → `.config/orca/keybindings.json`、`dot_zshrc` `dot_zprofile` `dot_p10k.zsh` → `.zshrc` `.zprofile` `.p10k.zsh`、nvim の `dot_gitignore` `dot_neoconf.json`、yazi plugins の `readonly_*`。`.chezmoiignore` を `git rm`。**ここから chezmoi は使えない**（source 名が変わるため）。使わないので問題ない | `git status` に rename として出る（`git log --follow` で履歴が繋がる）。`find . -name 'dot_*' -o -name 'private_*' -o -name 'executable_*' -o -name 'readonly_*'` が空 |
| 3 | nix 追加。`flake.nix` に input と modules、`nix/home/{default,dotfiles}.nix` 新規、`homebrew.nix` から `chezmoi` を外す。`git add` → `nix build --no-link ./nix#darwinConfigurations.BNMAC00101.system` | build 成功（未知オプション・型違いの検出）。`flake.lock` に home-manager / nix-homebrew が追加される |
| 4 | brew dry-run。`nix eval --raw ./nix#darwinConfigurations.BNMAC00101.config.homebrew.brewfile > "${TMPDIR:-/tmp}/Brewfile"` → `brew bundle cleanup --file=...`（`--force` 無し） | 削除候補が `chezmoi` だけ |
| 5 | `sudo darwin-rebuild check --flake ./nix`。HM の衝突チェックは `backupFileExtension` が設定されていれば警告のみでエラーにしない（§8.1）ので、実ファイルが残っていても止まらない | `ok` |
| 6 | 移動。`mv ~/.local/share/chezmoi ~/dotfiles`。`cd ~/dotfiles && direnv allow` | `git -C ~/dotfiles status` が動く |
| 7 | `sudo darwin-rebuild switch --flake ~/dotfiles/nix`。この 1 回で nix-homebrew の autoMigrate、brew cleanup（chezmoi 削除）、HM による実ファイルの `*.hm-backup` 退避と symlink 配置が全て行われる | §7 の検証を全て通す |
| 8 | 掃除。`find ~ -maxdepth 5 -name '*.hm-backup'` の一覧が対応表と一致することを見てから削除。`rm -rf ~/.config/chezmoi`（API キー 2 つを含む。控えるならこの前に）。`ya pkg install` で `git.yazi` を再取得してコミット | `*.hm-backup` が 0 件、`which chezmoi` が空 |
| 9 | `.zshrc` の `nvim-sync` を §4.6 に書き換え、README を §6 に書き換え、コミット | 新シェルで `nvim-sync` が「変更なし」を返す |
| 10 | `sudo darwin-rebuild --rollback` → `sudo darwin-rebuild switch --flake ~/dotfiles/nix` で世代の往復 | 往復成功。rollback 中も symlink は残る（§7 ロールバックの限界） |

手順 7 の前に `~/.local/share/chezmoi` は存在しなくなるので、memory と Phase 1 設計書に書いた運用コマンドのパスは `~/dotfiles/nix` に読み替える。

## 6. 別マシンでの再現手順（Phase 2 完了後）

1. Determinate Nix をインストール: `curl -fsSL https://install.determinate.systems/nix | sh -s -- install`
2. clone: `nix run nixpkgs#git -- clone https://github.com/hiroto0701/dotfiles ~/dotfiles`
   （リポジトリは public なので鍵不要。SSH 鍵を入れた後で remote を `git@` に切り替える）
3. ホスト名が `BNMAC00101` 以外なら `nix/flake.nix` の `hosts` に 1 行追加して `git add`
4. `sudo nix run nix-darwin/master#darwin-rebuild -- switch --flake ~/dotfiles/nix#<host>`
   （Homebrew 本体 → formula / cask → dotfiles symlink まで 1 回で入る）。
   Phase 1 ではこの `nix run` 経由の初回 switch が `/nix/var/nix/profiles/system` を作らなかった（原因未確定）。
   `ls /nix/var/nix/profiles/` に `system` が無ければ、Phase 1 プランの実行記録にある `nix-env -p ... --set` で世代 1 を作る
5. ログアウト / ログイン
6. 初回のシェル起動で zinit が自身を clone、初回の `nvim` で lazy.nvim がプラグインを入れる。`ya pkg install` で yazi プラグイン

手作業で残るもの: SSH 鍵、TCC 権限（Accessibility、Input Monitoring）、アプリのログイン、
cask 化していない GUI アプリ（Orca、Raycast、Logi Options+、Chrome、Cursor、Docker Desktop）、Phase 3 までの nodebrew / volta / pyenv / mise。

## 7. 検証

| 階層 | 手段 | 何を検出するか |
|---|---|---|
| 型・存在 | `nix build --no-link <flake>#darwinConfigurations.BNMAC00101.system` | 未知オプション、型違い、`users.users.<name>.home` 未設定 |
| 事前 | `darwin-rebuild check`、`brew bundle cleanup`（`--force` 無し） | `/etc` の衝突、brew の削除候補 |
| symlink 化 | `readlink -f ~/.config/nvim` が `~/dotfiles/.config/nvim`。対応表の全 target で `test -L`。`find ~ -maxdepth 5 -name '*.hm-backup'` が対応表の件数（15 件: dir 7 + file 8）と一致 | 実ファイルが残っていないか、想定外のものを退避していないか |
| 双方向即時反映 | リポジトリ側のファイルを編集して target 側で `cat`。`nvim` を起動して `lazy-lock.json` が変わったら `git -C ~/dotfiles status` に出る | 「apply」工程が消えたこと |
| brew | `which brew` が `/run/current-system/sw/bin/brew`、`brew list --full-name` が Phase 1 の宣言（brew 37 / cask 6 / tap 5）と一致、`brew list chezmoi` が失敗、`brew services list` で borders が started | nix-homebrew の移行で既存 keg が壊れていないか |
| shell | 新しいターミナルで p10k プロンプト、`alias ls` が lsd、`nvim-sync` が動く、`~/.local/bin/difit-cmux` が実行できる | `.zshrc` `.zprofile` `.p10k.zsh` `.local/bin` のリンク |
| Claude Code | 新セッションで `/grill-with-docs` `/llm-wiki` がスキル一覧に出る | symlink 化したスキルを読めるか |
| アプリ | aerospace のリロード、ghostty / wezterm の新ウィンドウ、yazi 起動、lazygit 起動、cmux / herdr / Orca の設定が効いている | dir 単位リンクの読み込み |
| 世代 | `darwin-rebuild --rollback` → 再 switch | ロールバック経路が生きているか |

### ロールバックの限界

`--rollback` は前世代（home-manager を含まない世代 4）の activation を再実行するだけで、HM が置いた symlink は消えない。
また前世代には HM の cleanup が無いので、symlink を消すのも手作業になる。
完全に戻すには `*.hm-backup` を元の名前に `mv` で戻す。そのため手順 8 の掃除は §7 の検証を全部通してから行う。
nix-homebrew の autoMigrate も戻らないが、brew の Cellar / Caskroom は保たれるので実害はない。

## 8. 調査で判明した事実（根拠）

### 8.1 home-manager のファイル配置の挙動（`modules/files.nix`、`modules/files/check-link-targets.sh`、2026-09-15 時点の master）

- 配置前チェック（`checkLinkTargets`）は、target が存在して HM 世代への symlink でない場合に `cmp -s` で内容を比較する。
  同一なら「is in the way ... will be skipped since they are the same」と警告するだけでエラーにしない
- 配置（`linkGeneration` の slow path）は、`HOME_MANAGER_BACKUP_EXT` が設定されていれば target を `<target>.<ext>` に `mv` してから `ln -Tsf` する。
  **設定されていなければ、同一内容の実ファイルは「identical なので何もしない」で残る。** つまり symlink に置き換わらない
- ディレクトリが target に居る場合も `mv` で退避されるので、dir 単位のリンクでも同じ仕組みで移行できる
- `home.fileActivator` の既定は `"legacy"`。上記は legacy の挙動
- `nix-darwin/default.nix`: HM の activation は nix-darwin の `system.activationScripts.postActivation` に追記され、
  `launchctl asuser <uid> sudo -u <user> --set-home` でユーザーとして実行される。`backupFileExtension` は環境変数 `HOME_MANAGER_BACKUP_EXT` として渡される
- `nixos/common.nix`: `home.username` は `users.users.<name>.name`、`home.homeDirectory` は `users.users.<name>.home` から取る。
  nix-darwin の `users.users.<name>.home` は既定 `null`（`modules/users/user.nix`）なので明示が必要
- `lib.file.mkOutOfStoreSymlink` は `runCommandLocal` で `ln -s <絶対パス> $out` するだけの派生物。ディレクトリでもファイルでも同じ
- `home.stateVersion` の現行最大は `"26.11"`（`modules/misc/version.nix`）

### 8.2 nix-homebrew（README、2026-09-15 時点）

- Homebrew 本体だけを入れ、formula / cask は管理しない。nix-darwin の `homebrew.*` と併用する設計
- 公式スクリプトで入れた既存インストールは `autoMigrate = true` で引き継ぐ
- `mutableTaps = true` なら `brew tap` は従来どおり使え、nix-darwin の `homebrew.taps` と共存できる
- `trust.{formulae,casks,commands,taps}` で Homebrew 7 の tap 信頼を activation 時に宣言できる。リストから外しても trust は自動では消えない（`brew untrust`）
- `/run/current-system/sw/bin/brew` にランチャーが置かれる
- brew 本体のバージョンは flake input で固定されるため、`brew update` で brew 自身は上がらない。`nix flake update` で上げる

### 8.3 Orca の設定パス（`/Applications/Orca.app/Contents/Resources/app.asar`、2026-09-15 時点）

- main プロセスに `function lJi(e){return join(e, ".orca", "keybindings.json")}` があり、`~/.orca/keybindings.json` 固定
- `XDG_CONFIG_HOME` の文字列はバンドル内に 117 箇所あるが、Orca 自身の設定パスの解決には使われていない
- `~/.orca/agent-hooks/` にランタイムファイルがある

### 8.4 現在の環境（2026-09-15）

- chezmoi 管理 55 ファイル（`chezmoi managed --include=files,symlinks`）。テンプレート 0、スクリプト 0、`.chezmoiignore` 1 つ
- `~/.config/chezmoi/chezmoi.toml` の `[data]` に API キーが 2 つあるが、参照するテンプレートが無い
- 未管理: `~/.zprofile`（`brew shellenv` 1 行）、`~/.p10k.zsh`（94 KB）
- 未コミット: `dot_config/ghostty/config`（ctrl+space prefix の keybind 追加）、`dot_orca/`
- drift: `~/.config/herdr/config.toml` は実機側に `[experimental] kitty_graphics = true` があり、source に無い（`MM`）
- `chezmoi unmanaged` で見つかったランタイムファイル: cmux `cmux.json`、herdr `.plugins.lock` `herdr-client.log` `herdr-server.log` `herdr.sock` `release-notes.json` `session.json`、
  yazi `plugins/git.yazi`、orca `agent-hooks/`、lazygit `state.yml`。aerospace / ghostty / wezterm / nvim は無し
- `dot_local/bin/executable_difit-cmux` は git 上 100644（chezmoi の接頭辞で実行ビットを付けていた）
- `~/.claude/skills/terminal-browser` は既に外部への symlink で、Claude Code はそれを読めている
- `ghq root` は `~/develop`。`~/dotfiles` は未使用
- リポジトリ `hiroto0701/dotfiles` は public
- Phase 1 で手動実行した `brew trust --tap` の対象は 5 tap（`~/.homebrew/trust.json`）
- mozumasu/dotfiles の該当箇所: `dotfilesPath = "${config.home.homeDirectory}/dotfiles"`、`mkLink = path: config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/${path}"`、
  herdr は `config.toml` のみ file 単位でリンク（ランタイムファイルを避けるため）、`backupFileExtension = "backup"`、
  home-manager は `home-manager.darwinModules.home-manager` として組み込み、brew 本体は nix-homebrew（`autoMigrate = true`、`mutableTaps = true`）

## 9. リスクと対処

| リスク | 対処 |
|---|---|
| `backupFileExtension` 無しで switch して実ファイルが残る | §3 で必須と決定。検証で `test -L` を全 target に当てる |
| nix-homebrew の autoMigrate で既存の keg が壊れる | Cellar / Caskroom は保たれる設計。switch 後に `brew list --full-name` と `brew services list` で Phase 1 の状態と突合 |
| `~/.config/nvim` の退避で `lazy-lock.json` 以外の実行時ファイルを失う | `chezmoi unmanaged` で nvim 配下に未管理ファイルが無いことを確認済み。`*.hm-backup` は検証後まで残す |
| yazi の `plugins/git.yazi` が退避されて一時的に消える | 手順 8 で `ya pkg install` により再取得し、コミットして以後は管理下に置く |
| Claude Code が symlink 化した skills を読まない | `~/.claude/skills/terminal-browser` が symlink で動いている実績あり。検証で `/grill-with-docs` を確認 |
| `~/dotfiles/.claude/` にプロジェクト用の `settings.local.json` 等が書かれてリポジトリに混ざる | 現状の repo root `.claude/` は空ディレクトリ。出てきたら `.gitignore` に足す |
| 手順 2 以降 chezmoi が使えない状態で手順 7 まで進む | 手順 2〜6 はファイル操作と build のみで実機に影響しない。実機への変更は手順 7 の 1 回 |
| リポジトリ移動後に flake のパスを間違える | 運用コマンドを `~/dotfiles/nix` に統一し、memory と README に書く |
| `--rollback` で symlink が戻らない | §7 ロールバックの限界。`*.hm-backup` からの手動復元手順を README に書く |
| Orca が将来 XDG 対応したら対応表の例外が不要になる | その時に `dotfiles.nix` の 1 行を変えるだけ |

## 10. Phase 3 への接続点

- `nix/home/packages.nix` を追加して `home/default.nix` の imports に足す。`homebrew.nix` の brews のうち `im-select` と `nodebrew` 以外は
  nixpkgs にある（2026-09-15 に flake.lock の nixpkgs で確認）。`borders` は `jankyborders` として nix-darwin の `services.jankyborders` で立てられる。
  `whisper.cpp` `sdl2-compat` `expat` は brew 側の依存解決のためだけに宣言しているので、`ffmpeg-full` が nixpkgs に移れば宣言ごと消える
- `.zshrc` の PATH 行（nodebrew / volta / pyenv / `/opt/homebrew/opt/*` 直パス）はそのときに整理する。ファイルは symlink なので編集即反映
- cask は brew に残す（`dockdoor` は nixpkgs に無い。GUI アプリは cask のほうが自動更新と署名まわりで安定）
