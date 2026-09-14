# nix-darwin Phase 1 設計: macOS 設定と Homebrew の宣言化

作成日: 2026-09-14
対象マシン: BNMAC00101 (macOS 26.1, Apple Silicon, ユーザー `mac83009105`)
状態: 設計承認済み。実装プランは別ファイル（`docs/superpowers/plans/`）

## 1. 背景と目的

dotfiles は chezmoi（`~/.local/share/chezmoi`、57 ファイル、テンプレート 0、スクリプト 0）で
管理できているが、次の 2 層がどこにも記録されていない。

- macOS のシステム設定（ポインタ速度、キーリピート、Caps Lock での IME 切替、Dock、Finder など）
- Homebrew の状態（formula 179 本 = 意図的インストール 36 本 + 依存、cask 7 本。Brewfile 無し）

Phase 1 では nix-darwin を導入し、この 2 層を宣言的に管理する。dotfiles は chezmoi のまま触らない。

### 段階計画における位置

| Phase | 内容 | 状態 |
|---|---|---|
| 1 | nix-darwin で `system.defaults` + `homebrew` を宣言化。chezmoi 継続 | **本設計** |
| 2 | home-manager で dotfiles を移し chezmoi を退役（nvim は `mkOutOfStoreSymlink`） | 未着手 |
| 3 | brew の CLI を nixpkgs へ、nodebrew/volta/pyenv を devShell へ | 未着手 |

## 2. スコープ

### 含む

- Determinate Nix と nix-darwin の導入
- `system.defaults` による macOS 設定の宣言（§5 の A 層 + B 層）
- `homebrew` モジュールによる tap 5 / brew 36 / cask 7 の宣言と `cleanup = "uninstall"` による収束
- ホスト名・ユーザー名のパラメータ化（複数台対応の骨格）
- chezmoi との同居（`.chezmoiignore`）
- `dot_zshrc` の PATH リセット行の修正（1 行）

### 含まない

- home-manager、dotfiles の移行
- brew パッケージの nixpkgs 置き換え
- キーボードショートカット（`com.apple.symbolichotkeys`、59 件中 21 件を無効化済み）
- brew 外で入れたアプリの cask 化（Raycast、Logi Options+、Chrome、Cursor、Docker Desktop）
- VS Code / Cursor 拡張、npm グローバル、uv ツール
- TCC 権限（Accessibility、Input Monitoring）
- Logi Options+ の設定、OpenLogi の導入
- `.zshrc` の PATH 行以外の整理、AltTab の残骸 LaunchAgent の削除
- Stage Manager 系の 3 キー（`WindowManager.AutoHide` / `HideDesktop` / `AppWindowGroupingBehavior`。意図不明のため除外）
- `SoftwareUpdate` / SMB 名 / ロケール / Magic Mouse 設定 / `screencapture`

## 3. 決定事項

| 論点 | 決定 | 理由 |
|---|---|---|
| flake の置き場所 | chezmoi リポジトリ内 `nix/` | リポジトリと履歴を 1 つに保ち、Phase 2 の移行も同一リポジトリ内で行う |
| Nix ディストリビューション | Determinate Nix（Determinate Nix Installer の既定） | flakes が標準で有効。macOS アップデート耐性 |
| nixpkgs / nix-darwin のチャンネル | `nixpkgs-unstable` / `nix-darwin/master` | Phase 1 では nix でパッケージを入れないためチャンネル差は小さい。ntsk 氏の構成と揃える |
| Homebrew の未宣言物 | `onActivation.cleanup = "uninstall"` | 状態を宣言に収束させる。cask のアプリデータは消さない（`zap` は採らない） |
| `system.defaults` の範囲 | 棚卸しで見つけた A 層（変更済み）+ B 層（既定値の明示） | 手で変えた設定の取りこぼしを防ぐ。C 層は別タスク |
| 反映の補助 | `activateSettings -u` をプライマリユーザーで実行 | ログアウト無しで反映される項目を増やす。効かなければ実装時に外す |
| 構成 | flake + 責務ごとの小モジュール（4 ファイル） | Phase 2 で `home/` を足すだけで拡張できる |
| 複数台対応 | `hosts` マップでホスト名×ユーザー名を生成 | 別 PC は 1 行追加で対応。今のうちに構造だけ作る |
| 検証スクリプト | 作らない | 検証コマンドをプランに列挙する。将来必要なら追加 |

## 4. 構成

### 4.1 ディレクトリ

```
~/.local/share/chezmoi/            # chezmoi ソース = git リポジトリ root
├── .chezmoiignore                 # 新規: nix / docs / README.md を配置対象から除外
├── nix/
│   ├── flake.nix
│   ├── flake.lock                 # 初回 build で生成。commit する
│   └── darwin/
│       ├── default.nix            # ホスト共通の土台
│       ├── defaults.nix           # system.defaults
│       └── homebrew.nix           # taps / brews / casks
├── docs/superpowers/specs/        # 設計書（本ファイル）
├── dot_zshrc                      # 15 行目のみ修正
└── dot_config/ ...                # 既存。Phase 1 では触らない
```

### 4.2 `nix/flake.nix`

```nix
{
  description = "nix-darwin configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:nix-darwin/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nix-darwin, nixpkgs }:
    let
      hosts = {
        BNMAC00101 = { user = "mac83009105"; };
      };
    in {
      darwinConfigurations = builtins.mapAttrs (hostname: h:
        nix-darwin.lib.darwinSystem {
          modules = [ ./darwin ];
          specialArgs = { inherit self hostname; username = h.user; };
        }) hosts;
    };
}
```

- `darwin-rebuild` は `scutil --get LocalHostName` を既定の設定名として使う（ソース確認済み）。
  別ホスト名のマシンでは `--flake <path>#BNMAC00101` と明示する。
- flake は git が追跡しているファイルしか見ない。新規ファイルは `git add` してから build する。

### 4.3 `nix/darwin/default.nix`

```nix
{ self, username, ... }:
{
  imports = [ ./defaults.nix ./homebrew.nix ];

  nixpkgs.hostPlatform = "aarch64-darwin";

  # system.defaults と homebrew はこのユーザーとして実行される
  system.primaryUser = username;

  # Determinate Nix が Nix 本体（/etc/nix/nix.conf、daemon）を管理するため nix-darwin 側は手放す
  nix.enable = false;

  system.stateVersion = 7;
  system.configurationRevision = self.rev or self.dirtyRev or null;

  # defaults write 後にログアウト無しで反映される項目を増やす
  system.activationScripts.postActivation.text = ''
    sudo -u ${username} /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u
  '';
}
```

- `ids.gids.nixbld` は `stateVersion >= 5` で既定 350。Determinate Nix Installer が作る gid と一致するので設定不要。
- `environment.systemPackages` は空。Phase 1 では nix でパッケージを入れない。
- `programs.zsh.enable` は既定 true のまま。nix-darwin が `/etc/zshenv` `/etc/zprofile` `/etc/zshrc` を生成する。
  変わる点: `SHARE_HISTORY` 有効、`SAVEHIST`/`HISTSIZE` が 2000、`compinit` が 1 回走る、
  PATH に `/run/current-system/sw/bin` と `/nix/var/nix/profiles/default/bin` が入る。`~/.zshrc` は触らない。

### 4.4 `nix/darwin/defaults.nix`

値はすべて 2026-09-14 時点の `defaults read` の実測値。

```nix
{ ... }:
{
  system.defaults = {
    NSGlobalDomain = {
      AppleInterfaceStyle = "Dark";
      KeyRepeat = 2;
      InitialKeyRepeat = 15;
      "com.apple.trackpad.scaling" = 3.0;
      "com.apple.swipescrolldirection" = true;
      "com.apple.trackpad.forceClick" = true;
      "com.apple.trackpad.enableSecondaryClick" = true;
      "com.apple.mouse.tapBehavior" = 1;
      NSAutomaticCapitalizationEnabled = true;
      NSAutomaticPeriodSubstitutionEnabled = true;
      NSTableViewDefaultSizeMode = 1;      # サイドバーアイコン: 小
      _HIHideMenuBar = false;
    };
    ".GlobalPreferences"."com.apple.mouse.scaling" = 2.5;
    hitoolbox.AppleFnUsageType = "Show Emoji & Symbols";   # 実値 2

    dock = {
      autohide = true;
      orientation = "left";
      tilesize = 16;
      magnification = true;
      largesize = 71;
      show-recents = false;
      mru-spaces = false;
      expose-group-apps = true;
      wvous-br-corner = 14;                # 右下ホットコーナー: クイックメモ
    };

    finder = {
      FXPreferredViewStyle = "clmv";       # カラム表示
      NewWindowTarget = "Recents";         # 実値 PfAF
      ShowPathbar = true;
      ShowExternalHardDrivesOnDesktop = true;
      ShowHardDrivesOnDesktop = false;
      ShowRemovableMediaOnDesktop = true;
    };

    trackpad = {
      Clicking = true;
      TrackpadRightClick = true;
      TrackpadThreeFingerDrag = true;
      # 3 本指ドラッグ有効時の連動値: 3 本指スワイプ/タップ = 0、4 本指 = 2
      TrackpadThreeFingerHorizSwipeGesture = 0;
      TrackpadThreeFingerVertSwipeGesture = 0;
      TrackpadThreeFingerTapGesture = 0;
      TrackpadFourFingerHorizSwipeGesture = 2;
      TrackpadFourFingerVertSwipeGesture = 2;
      TrackpadFourFingerPinchGesture = 2;
    };

    menuExtraClock = {
      ShowSeconds = true;
      ShowDayOfWeek = true;
      ShowAMPM = true;
      ShowDate = 0;
    };

    controlcenter = {
      BatteryShowPercentage = true;
      # false = メニューバーに出さない (実値 24)。nix-darwin の命名がこうなっている
      Bluetooth = false;
      Display = false;
    };

    WindowManager.EnableTiledWindowMargins = false;
    spaces.spans-displays = false;
    loginwindow.GuestEnabled = false;

    # 型付きオプションが無いものは domain/key を直接書く
    CustomUserPreferences = {
      NSGlobalDomain = {
        TISRomanSwitchState = 1;                       # Caps Lock で IME 切替
        "com.apple.scrollwheel.scaling" = 1.7;
        AppleMenuBarVisibleInFullscreen = true;
        "com.apple.sound.uiaudio.enabled" = 0;
        UIPreferredContentSizeCategoryName = "UICTContentSizeCategoryXS";
      };
      "com.apple.finder".ShowSidebar = false;
    };
  };
}
```

型は nix-darwin ソースで確認済み（`KeyRepeat`: int、`com.apple.trackpad.scaling`: float、
`NSTableViewDefaultSizeMode`: enum [1 2 3]、`Trackpad*Gesture`: enum [0 2] または [0 1 2]、
`controlcenter.Bluetooth`: bool → 18/24、`menuExtraClock.ShowDate`: enum [0 1 2]、
`finder.NewWindowTarget`: enum 文字列、`hitoolbox.AppleFnUsageType`: enum 文字列）。

### 4.5 `nix/darwin/homebrew.nix`

```nix
{ ... }:
{
  homebrew = {
    enable = true;                        # Homebrew 本体は事前に入っている前提。nix-darwin は入れない
    onActivation = {
      cleanup = "uninstall";              # 宣言に無い formula / cask / tap を削除。宣言物の依存は残る
      autoUpdate = false;
      upgrade = false;
    };

    taps = [
      { name = "daipeihust/tap"; trusted = true; }
      { name = "felixkratz/formulae"; clone_target = "https://github.com/FelixKratz/homebrew-formulae"; trusted = true; }
      { name = "jesseduffield/lazydocker"; trusted = true; }
      { name = "nikitabobko/tap"; trusted = true; }
      { name = "oven-sh/bun"; trusted = true; }
    ];

    brews = [
      "bat" "chezmoi" "coreutils" "direnv" "expat" "fd"
      { name = "ffmpeg-full"; link = true; }
      "fzf" "gh" "ghq" "git" "go" "herdr" "hunk"
      { name = "imagemagick-full"; link = true; }
      "jq" "lazygit" "lazysql" "lsd" "neovim" "nkf" "nodebrew" "poppler" "redis"
      "resvg" "ripgrep" "sevenzip" "tmux" "tree-sitter" "tree-sitter-cli" "yazi" "zoxide"
      "daipeihust/tap/im-select"
      { name = "felixkratz/formulae/borders"; start_service = true; }
      "jesseduffield/lazydocker/lazydocker"
      "oven-sh/bun/bun"
    ];

    casks = [
      "nikitabobko/tap/aerospace"
      "cmux"
      "dockdoor"
      "font-fira-code-nerd-font"
      "gcloud-cli"
      "ghostty"
      "wezterm"
    ];
  };
}
```

- 現在の tap のうち `manaflow-ai/cmux`（cmux は公式 cask に移った）と `idoavrah/homebrew`（uv 用）は
  宣言しないので cleanup で消える。
- `trusted = true` を tap 側に付ける。付けないと brew が formula の読み込みを拒否し、
  `brew leaves` / `brew bundle dump` から黙って落ちる（§8.1）。

### 4.6 chezmoi との同居

`.chezmoiignore`（ターゲットパス基準）:

```
nix
docs
README.md
```

- これで `chezmoi apply` が `~/nix` を作らなくなる。
- 副作用として、現在 `~/README.md` と `~/docs/yazi-keybindings.md` が誤配置されている問題も止まる。
  既に置かれている 2 つは chezmoi が消さないので手で `rm` する。
- chezmoi 側の運用（`chezmoi add`、`nvim-sync`）は無変更。

### 4.7 `dot_zshrc` の修正

15 行目 `export PATH=/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin` が `/etc/zshenv` で設定された
PATH を全消しするため、対話シェルで `nix` と `darwin-rebuild` が見つからなくなる。
末尾に `:$PATH` を足す（既存の順序は維持、nix のパスが後ろに残る）。Phase 1 で dotfiles に触る唯一の箇所。

## 5. 管理対象の macOS 設定（棚卸し結果）

判定基準: plist にキーが存在する = 一度は手で触った。

### A 層: 既定値から変えているもの

| 領域 | 設定 | 現在値 | 書き方 |
|---|---|---|---|
| 外観 | ダークモード | Dark | 型付き |
| キーボード | キーリピート / 開始遅延 | 2 / 15 | 型付き |
| キーボード | Caps Lock で IME 切替 | `TISRomanSwitchState = 1` | Custom |
| キーボード | Fn キー = 絵文字 | `AppleFnUsageType = 2` | 型付き |
| ポインタ | トラックパッド / マウス / スクロール速度 | 3.0 / 2.5 / 1.7 | 型付き / 型付き(`.GlobalPreferences`) / Custom |
| トラックパッド | タップでクリック、3 本指ドラッグ（連動値含む） | on / on | 型付き |
| Dock | 自動非表示・左・サイズ 16・拡大 71・最近の項目 off・Spaces 自動並替 off・アプリごとにグループ化 | | 型付き |
| Dock | 右下ホットコーナー = クイックメモ | 14 | 型付き |
| Finder | カラム表示・新規ウィンドウ = 最近の項目・パスバー | clmv / PfAF / on | 型付き |
| Finder | サイドバー非表示 | false | Custom |
| UI | サイドバーアイコン小 | `NSTableViewDefaultSizeMode = 1` | 型付き |
| UI | フルスクリーンでもメニューバー表示 | true | Custom |
| UI | UI サウンドエフェクト off | 0 | Custom |
| UI | 文字サイズ XS | `UICTContentSizeCategoryXS` | Custom |
| 時計 | 秒・曜日・AM/PM・日付 = 0 | | 型付き |
| コントロールセンター | バッテリー % 表示 | on | 型付き |
| コントロールセンター | Bluetooth / ディスプレイをメニューバーに出さない | 24 / 24 | 型付き（false） |
| ウィンドウ | タイル配置のマージン off | false | 型付き |

### B 層: 既定値だが明示するもの

ナチュラルスクロール on、強めのクリック on、副ボタンクリック on、タップ動作 1、
自動大文字 / ピリオド on、ディスプレイごとに Spaces off、デスクトップに外部 / リムーバブル表示 on、
内蔵ディスク非表示、ゲストログイン off、メニューバー常時表示。

### C 層: 対象外（§2 参照）

## 6. 導入手順（このマシン）

| # | 作業 | 確認 |
|---|---|---|
| 0 | 会社ポリシー確認（Intune 管理下で `/nix` ボリュームと LaunchDaemon の作成が問題ないか）。現在の defaults 全 domain を `~/defaults-before-nix-darwin.txt` にダンプ。社内パスを含むので **repo には入れない** | ファイル存在 |
| 1 | `.chezmoiignore` 追加、`~/README.md` `~/docs/` を削除 | `chezmoi managed` に出ない |
| 2 | Determinate Nix インストール: `curl -fsSL https://install.determinate.systems/nix \| sh -s -- install` | `nix --version`、`/nix` マウント |
| 3 | flake 骨格（`flake.nix` + `darwin/default.nix`、`defaults.nix` と `homebrew.nix` は空モジュール）。`git add` → `nix run nix-darwin/master#darwin-rebuild -- build --flake ~/.local/share/chezmoi/nix` → `sudo nix run nix-darwin/master#darwin-rebuild -- check --flake ~/.local/share/chezmoi/nix` → 初回 `sudo nix run nix-darwin/master#darwin-rebuild -- switch --flake ~/.local/share/chezmoi/nix`。この段階では `darwin-rebuild` が PATH に無いので `nix run` 経由。以後は `sudo darwin-rebuild ...` | `darwin-version`、`/etc/zshrc` が nix-darwin 生成に置換。`dot_zshrc` 修正 + `chezmoi apply` 後に新シェルで `darwin-rebuild` が見える |
| 4 | `defaults.nix` 投入 → build → `sudo darwin-rebuild switch --flake ~/.local/share/chezmoi/nix` | 各 domain を `defaults read` で読み戻して一致。ログアウト / ログイン後に体感確認 |
| 5 | `homebrew.nix` 投入 → build → `nix eval --raw ~/.local/share/chezmoi/nix#darwinConfigurations.BNMAC00101.config.homebrew.brewfile > "$TMPDIR/Brewfile"` で生成 Brewfile を取り出し、`brew bundle cleanup --file="$TMPDIR/Brewfile"`（`--force` 無し）で削除予定を目視 → switch | `brew leaves` / `brew tap` / `brew list --cask` が宣言と一致、`brew services list` で borders が started |
| 6 | `sudo darwin-rebuild --rollback` で世代を 1 つ戻し、再 switch で戻す | 世代の往復が成功 |

各ステップでコミットする。

### 別マシンでの再現手順（Phase 1 完了後）

1. Homebrew をインストール
2. Determinate Nix をインストール
3. `chezmoi init --apply <repo>`（dotfiles はここで配置）
4. `sudo nix run nix-darwin/master#darwin-rebuild -- switch --flake ~/.local/share/chezmoi/nix#BNMAC00101`
   （別ホスト名 / 別ユーザーなら `flake.nix` の `hosts` に 1 行足してその名前を指定）
5. 一度ログアウト / ログイン

## 7. 検証

| 階層 | 手段 | 何を検出するか |
|---|---|---|
| 型・存在 | `darwin-rebuild build` | 未知オプション、型違い |
| 事前 | `darwin-rebuild check` | `/etc` の衝突、nixbld gid、primaryUser 未設定 |
| brew dry-run | `nix eval --raw <flake>#darwinConfigurations.BNMAC00101.config.homebrew.brewfile` で Brewfile を取り出し、`brew bundle cleanup --file=...`（`--force` 無し） | 削除される formula / cask / tap の一覧 |
| 事後 | `defaults read` の読み戻し、`brew leaves` / `brew tap` / `brew list --cask` / `brew services list` | 宣言と実機の一致 |
| 世代 | `darwin-rebuild --rollback` → 再 switch | ロールバック経路が生きているか |

検証スクリプトは作らない。コマンドは実装プランに列挙する。

### 反映タイミング

nix-darwin の activation は `defaults write` の後に `killall Dock` だけを行う。
- 即時: Dock、ホットコーナー、コントロールセンター
- `activateSettings -u` で多くが即時化される見込み: キーリピート、外観、時計、Finder
- 残りはログアウト / ログイン: Caps Lock IME、トラックパッド（ByHost 側のキーは nix-darwin が書かない）

### ロールバックの限界

`--rollback` は前世代の activation を再実行して宣言済みの値を書き戻すだけ。
cleanup で消した brew パッケージは戻らず、宣言から外したキーも元の値には戻らない。
後者のために手順 0 のダンプを取る。

## 8. 調査で判明した事実（根拠）

### 8.1 Homebrew の tap 信頼機構が `brew leaves` を歪める

`brew list --full-name` には `daipeihust/tap/im-select` と `felixkratz/formulae/borders` が
インストール済みとして出るが、`brew leaves` と `brew bundle dump` には出ない。
原因は brew の tap 信頼機構: 未信頼 tap の formula は
`Refusing to load formula ... from untrusted tap` で読み込みを拒否され、集計から黙って落ちる。
`brew bundle dump` を信じて宣言を書いていたら、初回 cleanup で im-select（nvim の IME 切替）と
borders（ウィンドウ枠、`brew services` で常駐中）が消えていた。`nikitabobko/tap/aerospace`（cask）も同様。

### 8.2 nix-darwin の挙動（ソース確認、2026-09-14 時点の master）

- `nix.enable = false` で Nix 本体の管理を手放す（`managedDefault` の分岐）。Determinate Nix 併用時に必要
- `system.stateVersion` の現行最大は 7。`ids.gids.nixbld` は `stateVersion >= 5` で 350
- `system.defaults` は `system.primaryUser` として `defaults write` を実行。ByHost に書くのは
  `controlcenter` のみ。`NSGlobalDomain` は `-g`
- activation 後の反映処理は `killall Dock` のみ。`activateSettings -u` は呼ばない
- `trackpad` モジュールは `com.apple.AppleMultitouchTrackpad` と
  `com.apple.driver.AppleBluetoothMultitouch.trackpad` の両方に書く
- `homebrew` モジュールは Homebrew 本体を入れない。`taps.*.trusted` / `clone_target`、
  `brews.*.link` / `start_service` に対応
- 生成 Brewfile は `homebrew.brewfile` オプションとして `nix eval --raw` で取り出せる。
  switch 後は `HOMEBREW_BUNDLE_FILE` が store 内の Brewfile を指す
- `environment.systemPath` の既定は `/run/current-system/sw` と `/nix/var/nix/profiles/default`。
  `nix.enable = false` でも両方の `bin` が PATH に入る
- `darwin-rebuild` は `scutil --get LocalHostName` を既定の設定名にする。`--rollback` あり。
  `switch` / `check` / `rollback` は root 権限が必要
- `programs.zsh.enable` は既定 true。`/etc/zshrc` に `SHARE_HISTORY`、`HISTSIZE=2000`、
  `compinit` を書く。既存 `/etc/zshrc` が既知ハッシュ（Determinate インストーラ生成を含む）なら置換、
  未知なら activation を停止して退避手順を表示する
- `TISRomanSwitchState` は `CustomUserPreferences` の公式 example として載っている

### 8.3 現在の環境

- Intune による MDM 管理下（User Approved）。ユーザーは admin
- Nix 未インストール。`/nix` `/etc/synthetic.conf` 無し
- chezmoi に `.chezmoiignore` が無く、`README.md` と `docs/` が `~` に配置されている
- `~/.zshrc` 15 行目で PATH をリセットしている
- Logicool MX Master 3S を Bluetooth 直結で使用。Logi Options+ の設定は SQLite の BLOB 1 行で、
  どの手段でも宣言管理できない。OpenLogi（TOML 1 枚）は候補だが、3S × Bluetooth × macOS に
  未修正バグ（#1262 / #1263 / #1339）があるため Phase 1 では扱わない

### 8.4 棚卸しの方法

nix-darwin `modules/system/defaults/*.nix` から全オプション名を抽出し、対応する domain を
`defaults export` → plistlib で読み出して突合した。ByHost domain（controlcenter、screensaver、
NSGlobalDomain）は `-currentHost`、システム domain（loginwindow、SoftwareUpdate、smb）は
`/Library/Preferences` を直接読んだ。

## 9. リスクと対処

| リスク | 対処 |
|---|---|
| Intune 管理下で `/nix` ボリューム・LaunchDaemon 作成がポリシー違反 | 手順 0 で確認。`/nix/nix-installer uninstall` で完全撤去できる |
| `/etc/zshrc` 等が未知の内容で activation 停止 | nix-darwin が退避手順を表示して安全側に止まる |
| cleanup が想定外のものを消す | 手順 5 の dry-run で削除候補を目視 |
| ログアウトまで反映されない設定がある | `activateSettings -u` で緩和。残りはログアウトで確定 |
| ホスト名が MDM で変わる | `--flake <path>#BNMAC00101` を明示すれば影響なし |
| `activateSettings -u` が効かない、または副作用がある | 実装時に効果を確認し、無ければ外す |
| flake が未追跡ファイルを見ない | 新規ファイルは `git add` してから build する手順を守る |

## 10. Phase 2 以降への接続点

- `nix/home/` を追加し、`flake.nix` の `modules` に home-manager の darwin モジュールを足す
- nvim など実行時に書き込まれる設定は `config.lib.file.mkOutOfStoreSymlink` でリポジトリを直接指す
- OpenLogi を採用する場合、`~/.config/openlogi/config.toml` は TOML 1 枚なので chezmoi でも
  home-manager でも同じ方法で管理できる（デバイスキーは初回に OpenLogi に書かせる）
