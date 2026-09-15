# nix-darwin Phase 1 実装プラン: macOS 設定と Homebrew の宣言化

作成日: 2026-09-14
設計書: `/Users/mac83009105/.local/share/chezmoi/docs/superpowers/specs/2026-09-14-nix-darwin-phase1-design.md`
対象マシン: BNMAC00101 (macOS 26.1, aarch64-darwin, ユーザー `mac83009105`)

> **実行者へ:** タスクは上から順に実行する。各タスクの Step を 1 つずつ完了し、`[ユーザー実行]` の付いた Step は自分で実行せず、ユーザーに完全なコマンドを提示して結果を受け取る。

## Goal

chezmoi リポジトリ内に `nix/` flake を追加し、nix-darwin で macOS の `system.defaults` と Homebrew の状態を宣言管理する。dotfiles は chezmoi のまま触らない（`dot_zshrc` の 15 行目のみ例外）。

## Architecture

```
/Users/mac83009105/.local/share/chezmoi/     # chezmoi ソース = git root
├── .chezmoiignore                           # Task 2: nix / docs / README.md を配置対象から除外
├── dot_zshrc                                # Task 3: 15 行目のみ修正
└── nix/
    ├── flake.nix                            # Task 5: hosts マップから darwinConfigurations を生成
    ├── flake.lock                           # Task 5: 初回 build で生成、commit する
    └── darwin/
        ├── default.nix                      # Task 5: ホスト共通の土台 (primaryUser, nix.enable=false, postActivation)
        ├── defaults.nix                     # Task 5 で空、Task 6 で system.defaults を投入
        └── homebrew.nix                     # Task 5 で空、Task 7 で taps / brews / casks を投入
```

flake 出力 `darwinConfigurations.BNMAC00101` を `darwin-rebuild` がホスト名 (`scutil --get LocalHostName` = `BNMAC00101`) から自動選択する。

## Tech Stack

- Determinate Nix（flakes 標準有効）、nix-darwin master、nixpkgs-unstable
- Homebrew 7.0.1（`/opt/homebrew`、既にインストール済み。nix-darwin は Homebrew 本体を入れない）
- chezmoi v2.68.1

## 共通ルール（全タスクに適用）

1. **TDD の読み替え。** RED = コマンドが失敗する、または期待値と一致しない状態を示す。GREEN = build が通り、`nix eval` / `defaults read` / `brew` の読み戻しが期待値を返す。テストフレームワークも検証スクリプトも作らない。
2. **`[ユーザー実行]` の Step は実行者が実行しない。** sudo・対話・ログアウトが必要なため。ユーザーには Step に書かれたコマンドをそのまま提示する（ユーザーは `! <command>` で実行する）。結果の確認 Step（sudo 不要な読み取り）は実行者が行う。
3. **flake は git 追跡ファイルしか見ない。** 新規ファイルは build / eval の前に必ず `git add <file>` する。`nix/flake.lock` は初回 build で生成されるので、生成後に `git add` する。
4. **`git add -A` / `git add .` は禁止。** 触ったファイルだけを stage する。リポジトリには無関係な変更（`dot_config/ghostty/config` の修正、未追跡の `dot_orca/`）があり、巻き込んではいけない。`git status --short` の期待値は常にこの 2 行が残ったままである。
5. **`chezmoi apply` を引数無しで実行しない。** `~/.zshrc` と `~/.config/herdr/config.toml` にソース未反映のローカル変更があり（`chezmoi status` で `MM`）、全体 apply はそれを消す。apply は `chezmoi apply /Users/mac83009105/.zshrc` のようにターゲット指定でのみ行う。
6. **実行者は絶対パスでコマンドを打つ。** Bash の cwd と PATH は呼び出しごとにリセットされるため:
   - `nix` → `/nix/var/nix/profiles/default/bin/nix`（Task 4 以降）
   - `brew` → `/opt/homebrew/bin/brew`
   - `chezmoi` → `/opt/homebrew/bin/chezmoi`
   - `git` → `git -C /Users/mac83009105/.local/share/chezmoi`
   - `darwin-rebuild` / `darwin-version` → `/run/current-system/sw/bin/...`（Task 5 の switch 以降）
7. **build は `nix build --no-link` で行う。** `darwin-rebuild build` が内部で実行しているコマンドと同一で（`pkgs/nix-tools/darwin-rebuild.sh` で確認済み）、cwd に `result` シンボリックリンクを作らない。chezmoi ソースディレクトリに `result` が置かれると chezmoi が `~/result` の管理対象として扱ってしまうため、`darwin-rebuild build` は使わない。
8. **`nix eval` / `nix build` は `warning: Git tree '...' is dirty` を stderr に出す。** これは作業ツリーに未コミット変更があるためで、エラーではない。
9. コミットはタスクごとにローカルで行う。push はしない。メッセージは `<type>(<scope>): <日本語>`。
10. ユーザー向けコマンドで `sudo darwin-rebuild` が `command not found` になる場合は `sudo /run/current-system/sw/bin/darwin-rebuild` に読み替える。`sudo nix` が見つからない場合は `sudo /nix/var/nix/profiles/default/bin/nix`。

---

### Task 1: 事前確認と defaults の事前ダンプ（設計書 §6 手順 0）

**Files:**
- Create: `/Users/mac83009105/defaults-before-nix-darwin.txt`（リポジトリ外。社内情報を含むため commit 対象にしない）
- Modify: なし
- Test: なし（ファイル存在と domain 数で確認）

**Interfaces:**
- Consumes: なし
- Produces: `/Users/mac83009105/defaults-before-nix-darwin.txt`（Task 6 で宣言から外したキーを手で戻すときの参照元。設計書 §7「ロールバックの限界」）

- [ ] Step 1: **[ユーザー実行]** 会社ポリシーの確認

Intune 管理下（User Approved MDM）で、Determinate Nix Installer が行う次の変更が許可されるか情シス / Intune 管理者に確認する。

- `/etc/synthetic.conf` に `nix` エントリを追加し、`/nix` APFS ボリュームを作成する
- `/Library/LaunchDaemons/` に Nix デーモンの plist を追加する
- `_nixbld1` 〜 のビルド用ユーザーと `nixbld` グループ（GID 350）を作成する
- `/etc/zshrc` `/etc/bashrc` `/etc/zshenv` に Nix の初期化行を追記する（後で nix-darwin がこれらを `/etc/static/` へのシンボリックリンクに置き換える）

**NG の場合は Phase 1 全体を停止し、以降のタスクに進まない。**（撤去手段は `/nix/nix-installer uninstall`）

- [ ] Step 2: RED — ダンプがまだ無いことを確認

```sh
test -s /Users/mac83009105/defaults-before-nix-darwin.txt && echo EXISTS || echo MISSING
```

期待出力: `MISSING`

- [ ] Step 3: 設計書 §5 の全 domain を XML plist でダンプする

```sh
OUT=/Users/mac83009105/defaults-before-nix-darwin.txt
: > "$OUT"
for d in NSGlobalDomain com.apple.dock com.apple.finder com.apple.AppleMultitouchTrackpad com.apple.driver.AppleBluetoothMultitouch.trackpad com.apple.menuextra.clock com.apple.WindowManager com.apple.spaces com.apple.HIToolbox; do
  printf '## %s\n' "$d" >> "$OUT"
  defaults export "$d" - >> "$OUT"
  printf '\n' >> "$OUT"
done
printf '## com.apple.controlcenter [currentHost]\n' >> "$OUT"
defaults -currentHost export com.apple.controlcenter - >> "$OUT"
printf '\n## /Library/Preferences/com.apple.loginwindow\n' >> "$OUT"
defaults export /Library/Preferences/com.apple.loginwindow - >> "$OUT"
printf '\n' >> "$OUT"
```

`defaults export <domain> -` は型情報を保った XML plist を stdout に出す（`defaults read` より復元向き。復元は該当 `## ` セクションを別ファイルに切り出して `defaults import <domain> <file>`）。

- [ ] Step 4: GREEN — ファイルと domain 数を確認

```sh
test -s /Users/mac83009105/defaults-before-nix-darwin.txt && echo EXISTS
grep -c '^## ' /Users/mac83009105/defaults-before-nix-darwin.txt
grep -c '<plist version="1.0">' /Users/mac83009105/defaults-before-nix-darwin.txt
git -C /Users/mac83009105/.local/share/chezmoi status --short
```

期待出力:
- 1 行目 `EXISTS`
- 2 行目 `11`
- 3 行目 `11`
- git status は ` M dot_config/ghostty/config` と `?? dot_orca/` の 2 行のみ（ダンプはリポジトリ外なので現れない）

- [ ] Step 5: コミット — **なし**（リポジトリに変更が無い）

---

### Task 2: `.chezmoiignore` を追加し、誤配置された `~/README.md` と `~/docs/` を削除（設計書 §4.6, §6 手順 1）

**Files:**
- Create: `/Users/mac83009105/.local/share/chezmoi/.chezmoiignore`
- Delete（リポジトリ外）: `/Users/mac83009105/README.md`, `/Users/mac83009105/docs/yazi-keybindings.md`, `/Users/mac83009105/docs`（空になった場合のみ）
- Test: `chezmoi managed` / `chezmoi status` の出力

**Interfaces:**
- Consumes: なし
- Produces: `.chezmoiignore`（ターゲットパス基準で `nix` `docs` `README.md` を除外）。Task 3 以降のあらゆる `chezmoi apply` はこれが入っている前提で動く。Task 5 が作る `nix/` が `~/nix` に配置されなくなる

- [ ] Step 1: RED — 現在 `README.md` と `docs` が chezmoi の管理対象に入っていることを確認

```sh
/opt/homebrew/bin/chezmoi managed | grep -E '^(README\.md|docs)(/|$)'
```

期待出力（この 8 行が出る = 誤配置される状態）:
```
README.md
docs
docs/superpowers
docs/superpowers/plans
docs/superpowers/plans/2026-09-14-nix-darwin-phase1.md
docs/superpowers/specs
docs/superpowers/specs/2026-09-14-nix-darwin-phase1-design.md
docs/yazi-keybindings.md
```

- [ ] Step 2: `.chezmoiignore` を作成

`/Users/mac83009105/.local/share/chezmoi/.chezmoiignore` の全文:

```
nix
docs
README.md
```

- [ ] Step 3: GREEN — 管理対象から消えたことを確認

```sh
/opt/homebrew/bin/chezmoi managed | grep -cE '^(README\.md|docs|nix)(/|$)'
/opt/homebrew/bin/chezmoi status | grep -c ' docs'
```

期待出力: 両方 `0`（`grep -c` は 0 件で exit 1 になるが、出力の `0` が期待値）

- [ ] Step 4: 誤配置ファイルがリポジトリのコピーと同一であることを確認してから削除

```sh
diff /Users/mac83009105/.local/share/chezmoi/README.md /Users/mac83009105/README.md && echo SAME_README
diff /Users/mac83009105/.local/share/chezmoi/docs/yazi-keybindings.md /Users/mac83009105/docs/yazi-keybindings.md && echo SAME_YAZI
```

期待出力: `SAME_README` と `SAME_YAZI`（差分が出た場合は削除せず、差分内容を報告して停止する）

両方 SAME なら削除する:

```sh
rm /Users/mac83009105/README.md
rm /Users/mac83009105/docs/yazi-keybindings.md
ls -A /Users/mac83009105/docs | wc -l
```

期待出力: `0`（`~/docs` が空）。`0` なら:

```sh
rmdir /Users/mac83009105/docs
test ! -e /Users/mac83009105/README.md && test ! -e /Users/mac83009105/docs && echo REMOVED
```

期待出力: `REMOVED`

- [ ] Step 5: コミット

```sh
git -C /Users/mac83009105/.local/share/chezmoi add .chezmoiignore
git -C /Users/mac83009105/.local/share/chezmoi status --short
git -C /Users/mac83009105/.local/share/chezmoi commit -m "chore(chezmoi): nix と docs と README.md を配置対象から除外"
```

`status --short` の期待出力: `A  .chezmoiignore` と、共通ルール 4 の 2 行だけ。

---

### Task 3: `dot_zshrc` の PATH リセット行を修正（設計書 §4.7）

**Files:**
- Modify: `/Users/mac83009105/.local/share/chezmoi/dot_zshrc:15`（`chezmoi add` 後も同じ行番号。追記される mise の行は末尾）
- 配置先: `/Users/mac83009105/.zshrc`（`chezmoi apply` で反映）
- Test: `zsh -ic` による PATH 保持のプローブ

**Interfaces:**
- Consumes: Task 2 の `.chezmoiignore`（これが無い状態で `chezmoi apply` を打つと `docs/` が再配置される）
- Produces: `/etc/zshenv` `/etc/zshrc` が設定した PATH を `~/.zshrc` が保持するようになる。Task 4 以降、対話シェルで `nix` と `darwin-rebuild` が見つかる前提を作る

**前提の事実:** `chezmoi status` で `~/.zshrc` は `MM`（ソース未反映のローカル変更あり）。差分は末尾の `eval "$(/Users/mac83009105/.local/bin/mise activate zsh)"` 行。先にこれをソースへ取り込まないと `chezmoi apply` で消える。

- [ ] Step 1: ローカル変更をソースに取り込んでコミット

```sh
/opt/homebrew/bin/chezmoi diff /Users/mac83009105/.zshrc
/opt/homebrew/bin/chezmoi add /Users/mac83009105/.zshrc
git -C /Users/mac83009105/.local/share/chezmoi diff --stat dot_zshrc
```

期待出力: `chezmoi diff` は mise の行（と直前の空行）の削除差分だけを示す。`git diff --stat` は `dot_zshrc | 2 ++` 相当（追加 2 行、削除 0 行）。差分がそれ以外を含む場合は停止して報告する。

```sh
git -C /Users/mac83009105/.local/share/chezmoi add dot_zshrc
git -C /Users/mac83009105/.local/share/chezmoi commit -m "chore(zsh): ローカルの mise 初期化行を chezmoi に同期"
/opt/homebrew/bin/chezmoi status /Users/mac83009105/.zshrc
```

期待出力: `chezmoi status` が空（ソースとターゲットが一致）

- [ ] Step 2: RED — シェル起動前に置いた PATH エントリが `~/.zshrc` で消えることを確認

```sh
sed -n 15p /Users/mac83009105/.zshrc
PATH="/nix-probe:$PATH" zsh -ic 'print -r -- $PATH' 2>/dev/null | tr ':' '\n' | grep -cx '/nix-probe'
```

期待出力:
- 1 行目 `export PATH=/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin`
- 2 行目 `0`（プローブが消えている = `/etc/zshenv` が足した PATH も消える状態）

- [ ] Step 3: ソースの 15 行目を修正

`/Users/mac83009105/.local/share/chezmoi/dot_zshrc` の 15 行目を

```
export PATH=/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin
```

から

```
export PATH=/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin:$PATH
```

に変更する（末尾に `:$PATH` を足すだけ。他の行は触らない）。

- [ ] Step 4: ターゲットだけに apply して GREEN を確認

```sh
/opt/homebrew/bin/chezmoi apply /Users/mac83009105/.zshrc
/opt/homebrew/bin/chezmoi status /Users/mac83009105/.zshrc
sed -n 15p /Users/mac83009105/.zshrc
PATH="/nix-probe:$PATH" zsh -ic 'print -r -- $PATH' 2>/dev/null | tr ':' '\n' | grep -cx '/nix-probe'
zsh -ic 'print -r -- $PATH' 2>/dev/null | tr ':' '\n' | grep -cx '/opt/homebrew/bin'
```

期待出力:
- `chezmoi status` は空
- `export PATH=/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin:$PATH`
- `1`（プローブが残る）
- `1`（既存の brew の PATH も従来どおり入っている）

- [ ] Step 5: コミット

```sh
git -C /Users/mac83009105/.local/share/chezmoi diff dot_zshrc
git -C /Users/mac83009105/.local/share/chezmoi add dot_zshrc
git -C /Users/mac83009105/.local/share/chezmoi commit -m "fix(zsh): PATH リセット行が既存の PATH を消さないようにする"
```

`git diff` は 15 行目の 1 行だけの変更（`-`/`+` 各 1 行）であること。

---

### Task 4: Determinate Nix のインストール（設計書 §6 手順 2）

**Files:**
- Create / Modify: なし（リポジトリ外のシステム変更のみ）
- Test: `nix --version`、`/nix` マウント、`/etc` シェル設定ファイルのハッシュ

**Interfaces:**
- Consumes: Task 1 Step 1 の許可、Task 3（対話シェルで `nix` が見えるための PATH 修正）
- Produces: `/nix/var/nix/profiles/default/bin/nix`（以降の実行者コマンドはこの絶対パスを使う）、`/usr/local/bin/determinate-nixd`（nix-darwin の Determinate 検出に使われるファイル）、`/nix` ボリューム

- [ ] Step 1: RED — Nix が無いことを確認

```sh
test -x /nix/var/nix/profiles/default/bin/nix && echo PRESENT || echo ABSENT
test -d /nix && echo NIX_DIR || echo NO_NIX_DIR
```

期待出力: `ABSENT` と `NO_NIX_DIR`

- [ ] Step 2: **[ユーザー実行]** Determinate Nix をインストール

```sh
curl -fsSL https://install.determinate.systems/nix | sh -s -- install
```

インストーラが変更内容を表示して `Proceed? ([Y]es/[n]o/[e]xplain)` を聞くので `y` で進める。sudo パスワードを求められる。完了後、**新しいターミナルタブを開く**（`/etc/zshrc` への追記を読ませるため）。

- [ ] Step 3: GREEN — インストール結果を確認（実行者が実行。sudo 不要）

```sh
/nix/var/nix/profiles/default/bin/nix --version
zsh -ic 'nix --version' 2>/dev/null
mount | grep ' /nix '
test -x /usr/local/bin/determinate-nixd && echo DETERMINATE_NIXD
shasum -a 256 /etc/zshrc /etc/zshenv /etc/bashrc
grep -c 'nix-daemon.sh' /etc/profile
dscl . -read /Groups/nixbld PrimaryGroupID
git -C /Users/mac83009105/.local/share/chezmoi status --short
```

期待出力:
- 1〜2 行目: いずれも `nix (Determinate Nix ` で始まるバージョン文字列（2 行目は Task 3 の PATH 修正が効いている証拠。`command not found` なら Task 3 に戻る）
- `mount`: `/nix` に `apfs` ボリュームがマウントされている 1 行
- `DETERMINATE_NIXD`
- ハッシュは nix-darwin が「既知」として置換を許すもの（`modules/programs/zsh/default.nix`, `modules/programs/bash/default.nix` の `knownSha256Hashes` で確認済み）:
  - `/etc/zshrc`: `27274e44b88a1174787f9a3d437d3387edc4f9aaaf40356054130797f5dc7912`（macOS 26 用 Determinate）または `2af1b563e389d11b76a651b446e858116d7a20370d9120a7e9f78991f3e5f336`
  - `/etc/zshenv`: `d07015be6875f134976fce84c6c7a77b512079c1c5f9594dfa65c70b7968b65f`
  - `/etc/bashrc`: `08ffbf991a9e25839d38b80a0d3bce3b5a6c84b9be53a4b68949df4e7e487bb7`
  - どれか一致しない場合は Task 5 Step 7 の `check` で「Unexpected files in /etc」が出る。そこに退避手順を書いてあるので、ここでは値を記録して進む
- `grep -c`: `0`（`/etc/profile` に nix-daemon.sh の参照が無い。nix-darwin の `nixInstaller` チェックの条件）
- `PrimaryGroupID: 350`（参考値。`nix.enable = false` のためこのチェック自体は走らない）
- git status は共通ルール 4 の 2 行のみ

- [ ] Step 4: コミット — **なし**（リポジトリに変更が無い）

---

### Task 5: flake 骨格を作成し、初回 switch で nix-darwin を有効化（設計書 §4.2, §4.3, §6 手順 3）

**Files:**
- Create: `/Users/mac83009105/.local/share/chezmoi/nix/flake.nix`
- Create: `/Users/mac83009105/.local/share/chezmoi/nix/darwin/default.nix`
- Create: `/Users/mac83009105/.local/share/chezmoi/nix/darwin/defaults.nix`（空モジュール。Task 6 で中身を入れる）
- Create: `/Users/mac83009105/.local/share/chezmoi/nix/darwin/homebrew.nix`（空モジュール。Task 7 で中身を入れる）
- Create（生成物）: `/Users/mac83009105/.local/share/chezmoi/nix/flake.lock`
- Test: `nix eval` / `nix build` / `darwin-rebuild check` / switch 後の `/etc` と `/run/current-system`

**Interfaces:**
- Consumes: Task 4 の `/nix/var/nix/profiles/default/bin/nix`、Task 2 の `.chezmoiignore`（`nix/` を `~/nix` に配置させない）
- Produces:
  - flake 出力属性 `darwinConfigurations.BNMAC00101`（`nix build`/`nix eval` の属性パスは `/Users/mac83009105/.local/share/chezmoi/nix#darwinConfigurations.BNMAC00101.<...>`）
  - モジュールが受け取る `specialArgs`: `self`（flake 自身）、`hostname`（`"BNMAC00101"`）、`username`（`"mac83009105"`）
  - `nix/darwin/default.nix` が `./defaults.nix` と `./homebrew.nix` を import する。Task 6 / 7 はそれぞれのファイルの中身を置き換えるだけで、`default.nix` と `flake.nix` は触らない
  - `config.system.primaryUser = "mac83009105"`（`system.defaults` と `homebrew` はこのユーザーで実行される）
  - `/run/current-system/sw/bin/darwin-rebuild`、`/run/current-system/sw/bin/darwin-version`

- [ ] Step 1: RED — flake が存在しないことを確認

```sh
/nix/var/nix/profiles/default/bin/nix eval --json /Users/mac83009105/.local/share/chezmoi/nix#darwinConfigurations.BNMAC00101.config.system.stateVersion
```

期待結果: `error:` で終了する（`nix` ディレクトリが存在しない、または `flake.nix` を含まない旨）

- [ ] Step 2: `activateSettings` の実在を確認（設計書 §9 の前提）

```sh
ls -l /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings
```

期待出力: `-rwxr-xr-x ... root wheel ... activateSettings` の 1 行。存在しない場合は Step 4 の `default.nix` から `system.activationScripts.postActivation` ブロック（16〜22 行目）を除いて作成し、その旨を報告する。

- [ ] Step 3: `nix/flake.nix` を作成

`/Users/mac83009105/.local/share/chezmoi/nix/flake.nix` の全文:

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

- [ ] Step 4: `nix/darwin/default.nix` を作成

`/Users/mac83009105/.local/share/chezmoi/nix/darwin/default.nix` の全文:

```nix
{ self, username, ... }:
{
  imports = [ ./defaults.nix ./homebrew.nix ];

  nixpkgs.hostPlatform = "aarch64-darwin";

  # system.defaults と homebrew はこのユーザーとして実行される
  system.primaryUser = username;

  # Determinate Nix が Nix 本体 (/etc/nix/nix.conf、daemon) を管理するため nix-darwin 側は手放す
  nix.enable = false;

  system.stateVersion = 7;
  system.configurationRevision = self.rev or self.dirtyRev or null;

  # defaults write 後にログアウト無しで反映される項目を増やす。
  # activation script は set -e で動くため、失敗しても activation を止めないようにする
  system.activationScripts.postActivation.text = ''
    launchctl asuser "$(id -u -- ${username})" sudo --user=${username} -- \
      /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u \
      || echo >&2 "warning: activateSettings -u failed (ignored)"
  '';
}
```

設計書 §4.3 からの変更点（2 つ、いずれも nix-darwin ソースで確認した事実に基づく）:
- 実行形式を nix-darwin 自身が `defaults write` に使っている `launchctl asuser "$(id -u -- <user>)" sudo --user=<user> -- <cmd>` に揃えた（`modules/system/defaults-write.nix` の `userDefaultsToList`）。ユーザーの GUI セッション文脈で実行される
- `|| echo ... (ignored)` を付けた。activation script は `set -e` で動く（`modules/system/activation-scripts.nix`）ため、素の呼び出しが失敗すると `/run/current-system` の更新前に activation が中断する

- [ ] Step 5: 空モジュール 2 つを作成

`/Users/mac83009105/.local/share/chezmoi/nix/darwin/defaults.nix` の全文:

```nix
{ ... }:
{
}
```

`/Users/mac83009105/.local/share/chezmoi/nix/darwin/homebrew.nix` の全文:

```nix
{ ... }:
{
}
```

- [ ] Step 6: `git add` してから eval と build（実行者。sudo 不要）

```sh
git -C /Users/mac83009105/.local/share/chezmoi add nix/flake.nix nix/darwin/default.nix nix/darwin/defaults.nix nix/darwin/homebrew.nix
git -C /Users/mac83009105/.local/share/chezmoi status --short
```

期待出力: `A  nix/darwin/default.nix` `A  nix/darwin/defaults.nix` `A  nix/darwin/homebrew.nix` `A  nix/flake.nix` と共通ルール 4 の 2 行。

```sh
/nix/var/nix/profiles/default/bin/nix eval --json /Users/mac83009105/.local/share/chezmoi/nix#darwinConfigurations.BNMAC00101.config.system.stateVersion
/nix/var/nix/profiles/default/bin/nix eval --json /Users/mac83009105/.local/share/chezmoi/nix#darwinConfigurations.BNMAC00101.config.system.primaryUser
/nix/var/nix/profiles/default/bin/nix eval --json /Users/mac83009105/.local/share/chezmoi/nix#darwinConfigurations.BNMAC00101.config.nix.enable
/nix/var/nix/profiles/default/bin/nix eval --json /Users/mac83009105/.local/share/chezmoi/nix#darwinConfigurations.BNMAC00101.config.nixpkgs.hostPlatform.system
/nix/var/nix/profiles/default/bin/nix eval --json /Users/mac83009105/.local/share/chezmoi/nix#darwinConfigurations.BNMAC00101.config.homebrew.enable
/nix/var/nix/profiles/default/bin/nix eval --raw /Users/mac83009105/.local/share/chezmoi/nix#darwinConfigurations.BNMAC00101.config.system.activationScripts.postActivation.text | grep -c 'activateSettings -u'
```

期待出力（順に）: `7` / `"mac83009105"` / `false` / `"aarch64-darwin"` / `false` / `1`
（初回は nixpkgs と nix-darwin のダウンロードで数分かかる。最初の eval で `nix/flake.lock` が生成される）

```sh
/nix/var/nix/profiles/default/bin/nix build --no-link --print-out-paths /Users/mac83009105/.local/share/chezmoi/nix#darwinConfigurations.BNMAC00101.system
test ! -e /Users/mac83009105/.local/share/chezmoi/result && echo NO_RESULT_LINK
ls /Users/mac83009105/.local/share/chezmoi/nix/flake.lock
git -C /Users/mac83009105/.local/share/chezmoi add nix/flake.lock
git -C /Users/mac83009105/.local/share/chezmoi status --short nix/
```

期待出力:
- `/nix/store/<hash>-darwin-system-26.11.<7 文字>` の 1 行（この store パスを控える。Step 9 で照合する）
- `NO_RESULT_LINK`
- `flake.lock` が存在
- `status --short nix/` は 5 ファイルすべて `A `

- [ ] Step 7: **[ユーザー実行]** `darwin-rebuild check`（root 必須。`/etc` の衝突と primaryUser の実在を検査）

```sh
sudo nix run nix-darwin/master#darwin-rebuild -- check --flake /Users/mac83009105/.local/share/chezmoi/nix
```

期待出力: エラーを出さず exit 0 で終わる（`check` は成功時に何も表示しないことがある。`echo $?` で `0` を確認）。

`error: Unexpected files in /etc, aborting activation` が出た場合は、列挙されたファイル（例 `/etc/zshrc`）ごとに

```sh
sudo mv /etc/zshrc /etc/zshrc.before-nix-darwin
```

のように `.before-nix-darwin` を付けて退避し、`check` を再実行する（nix-darwin が指示する手順そのもの）。

- [ ] Step 8: **[ユーザー実行]** 初回 switch（この時点では `darwin-rebuild` が PATH に無いため `nix run` 経由）

```sh
sudo nix run nix-darwin/master#darwin-rebuild -- switch --flake /Users/mac83009105/.local/share/chezmoi/nix
```

期待出力: `building the system configuration...` → `setting up /etc...` などの activation ログが流れ、エラー無く終了する。`warning: activateSettings -u failed (ignored)` が **出ない**こと（出た場合は記録して Task 6 Step 7 の判断に使う）。

完了後、**新しいターミナルタブを開く**。

- [ ] Step 9: GREEN — switch 結果を確認（実行者。sudo 不要）

```sh
readlink /run/current-system
readlink /etc/zshrc
readlink /etc/zshenv
readlink /etc/bashrc
/run/current-system/sw/bin/darwin-version --configuration-revision
git -C /Users/mac83009105/.local/share/chezmoi rev-parse HEAD
zsh -ic 'command -v darwin-rebuild' 2>/dev/null
zsh -ic 'print -r -- $PATH' 2>/dev/null | tr ':' '\n' | grep -cx '/run/current-system/sw/bin'
```

期待出力:
- `readlink /run/current-system` = Step 6 の build が表示した store パス
- `/etc/static/zshrc` / `/etc/static/zshenv` / `/etc/static/bashrc`（nix-darwin 生成に置換された）
- `--configuration-revision` = `<rev-parse HEAD の値>-dirty`（`ghostty` の未コミット変更と `dot_orca/` があるため `-dirty` が付く）
- `/run/current-system/sw/bin/darwin-rebuild`（Task 3 の PATH 修正が効き、以後 `sudo darwin-rebuild ...` が使える）
- `1`

- [ ] Step 10: コミット

```sh
git -C /Users/mac83009105/.local/share/chezmoi status --short
git -C /Users/mac83009105/.local/share/chezmoi commit -m "feat(nix): nix-darwin の flake 骨格を追加"
```

`status --short` は `A  nix/flake.nix` `A  nix/flake.lock` `A  nix/darwin/default.nix` `A  nix/darwin/defaults.nix` `A  nix/darwin/homebrew.nix` と共通ルール 4 の 2 行だけであること（Step 6 で 5 ファイルを stage 済み。stage 漏れがあれば `git add nix/<file>` で個別に足す）。

---

### Task 6: `defaults.nix` を投入して macOS 設定を宣言（設計書 §4.4, §5, §6 手順 4）

**Files:**
- Modify: `/Users/mac83009105/.local/share/chezmoi/nix/darwin/defaults.nix`（Task 5 の 3 行の空モジュールを全文置換）
- Test: `nix eval` の値、switch 後の `defaults read` 読み戻し

**Interfaces:**
- Consumes: Task 5 の `darwinConfigurations.BNMAC00101`、`config.system.primaryUser`、`/run/current-system/sw/bin/darwin-rebuild`
- Produces: `config.system.defaults.*` の値（下表）。ByHost に書かれるのは `controlcenter` のみ、`NSGlobalDomain` は `-g`、`trackpad` は `com.apple.AppleMultitouchTrackpad` と `com.apple.driver.AppleBluetoothMultitouch.trackpad` の両方に書かれる（`modules/system/defaults-write.nix` で確認済み）

- [ ] Step 1: RED — まだ何も宣言されていないことを確認

```sh
/nix/var/nix/profiles/default/bin/nix eval --json /Users/mac83009105/.local/share/chezmoi/nix#darwinConfigurations.BNMAC00101.config.system.defaults.NSGlobalDomain.KeyRepeat
/nix/var/nix/profiles/default/bin/nix eval --json /Users/mac83009105/.local/share/chezmoi/nix#darwinConfigurations.BNMAC00101.config.system.defaults.CustomUserPreferences
```

期待出力: `null` と `{}`

- [ ] Step 2: `nix/darwin/defaults.nix` を全文置換

`/Users/mac83009105/.local/share/chezmoi/nix/darwin/defaults.nix` の全文（値は 2026-09-14 の `defaults read` 実測値。オプション名と型は `modules/system/defaults/*.nix` で確認済み）:

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

（`defaults.nix` は Task 5 で既に git 追跡済みなので `git add` 無しで flake から見える）

- [ ] Step 3: build と eval で型・値を確認（実行者）

```sh
/nix/var/nix/profiles/default/bin/nix build --no-link --print-out-paths /Users/mac83009105/.local/share/chezmoi/nix#darwinConfigurations.BNMAC00101.system
```

期待出力: `/nix/store/<hash>-darwin-system-26.11.<7 文字>` の 1 行（Task 5 とは別の hash。型違い・未知オプションがあればここで `error:` になる）

```sh
F=/Users/mac83009105/.local/share/chezmoi/nix
N=/nix/var/nix/profiles/default/bin/nix
$N eval --json $F#darwinConfigurations.BNMAC00101.config.system.defaults.NSGlobalDomain.KeyRepeat
$N eval --json $F#darwinConfigurations.BNMAC00101.config.system.defaults.hitoolbox.AppleFnUsageType
$N eval --json $F#darwinConfigurations.BNMAC00101.config.system.defaults.finder.NewWindowTarget
$N eval --json $F#darwinConfigurations.BNMAC00101.config.system.defaults.controlcenter.Bluetooth
$N eval --json $F#darwinConfigurations.BNMAC00101.config.system.defaults.trackpad.TrackpadThreeFingerDrag
$N eval --json $F#darwinConfigurations.BNMAC00101.config.system.defaults.CustomUserPreferences.NSGlobalDomain.TISRomanSwitchState
$N eval --json '/Users/mac83009105/.local/share/chezmoi/nix#darwinConfigurations.BNMAC00101.config.system.defaults.".GlobalPreferences"."com.apple.mouse.scaling"'
```

期待出力（順に）: `2` / `2`（enum 文字列が `apply` で数値化） / `"PfAF"` / `24`（false → 24） / `true` / `1` / `2.5`

- [ ] Step 4: **[ユーザー実行]** switch

```sh
sudo darwin-rebuild switch --flake /Users/mac83009105/.local/share/chezmoi/nix
```

期待出力: `user defaults...` → `restarting Dock...` を含み、エラー無く終了する。Dock が一度消えて再表示される。`warning: activateSettings -u failed (ignored)` が出たかどうかを控える。

- [ ] Step 5: GREEN — 全 domain を読み戻して宣言値と一致することを確認（実行者。sudo 不要）

```sh
for k in AppleInterfaceStyle KeyRepeat InitialKeyRepeat com.apple.trackpad.scaling com.apple.swipescrolldirection com.apple.trackpad.forceClick com.apple.trackpad.enableSecondaryClick com.apple.mouse.tapBehavior NSAutomaticCapitalizationEnabled NSAutomaticPeriodSubstitutionEnabled NSTableViewDefaultSizeMode _HIHideMenuBar TISRomanSwitchState com.apple.scrollwheel.scaling AppleMenuBarVisibleInFullscreen com.apple.sound.uiaudio.enabled UIPreferredContentSizeCategoryName; do printf 'NSGlobalDomain %s = ' "$k"; defaults read -g "$k"; done
printf '.GlobalPreferences com.apple.mouse.scaling = '; defaults read .GlobalPreferences com.apple.mouse.scaling
printf 'HIToolbox AppleFnUsageType = '; defaults read com.apple.HIToolbox AppleFnUsageType
for k in autohide orientation tilesize magnification largesize show-recents mru-spaces expose-group-apps wvous-br-corner; do printf 'dock %s = ' "$k"; defaults read com.apple.dock "$k"; done
for k in FXPreferredViewStyle NewWindowTarget ShowPathbar ShowExternalHardDrivesOnDesktop ShowHardDrivesOnDesktop ShowRemovableMediaOnDesktop ShowSidebar; do printf 'finder %s = ' "$k"; defaults read com.apple.finder "$k"; done
for d in com.apple.AppleMultitouchTrackpad com.apple.driver.AppleBluetoothMultitouch.trackpad; do for k in Clicking TrackpadRightClick TrackpadThreeFingerDrag TrackpadThreeFingerHorizSwipeGesture TrackpadThreeFingerVertSwipeGesture TrackpadThreeFingerTapGesture TrackpadFourFingerHorizSwipeGesture TrackpadFourFingerVertSwipeGesture TrackpadFourFingerPinchGesture; do printf '%s %s = ' "$d" "$k"; defaults read "$d" "$k"; done; done
for k in ShowSeconds ShowDayOfWeek ShowAMPM ShowDate; do printf 'clock %s = ' "$k"; defaults read com.apple.menuextra.clock "$k"; done
for k in BatteryShowPercentage Bluetooth Display; do printf 'controlcenter %s = ' "$k"; defaults -currentHost read com.apple.controlcenter "$k"; done
printf 'WindowManager EnableTiledWindowMargins = '; defaults read com.apple.WindowManager EnableTiledWindowMargins
printf 'spaces spans-displays = '; defaults read com.apple.spaces spans-displays
printf 'loginwindow GuestEnabled = '; defaults read /Library/Preferences/com.apple.loginwindow GuestEnabled
```

期待出力（`defaults read` は bool を `1`/`0`、float `3.0` を `3` と表示する）:

| 出力行 | 期待値 |
|---|---|
| NSGlobalDomain AppleInterfaceStyle | `Dark` |
| NSGlobalDomain KeyRepeat / InitialKeyRepeat | `2` / `15` |
| NSGlobalDomain com.apple.trackpad.scaling | `3` |
| NSGlobalDomain com.apple.swipescrolldirection / forceClick / enableSecondaryClick | `1` / `1` / `1` |
| NSGlobalDomain com.apple.mouse.tapBehavior | `1` |
| NSGlobalDomain NSAutomaticCapitalizationEnabled / NSAutomaticPeriodSubstitutionEnabled | `1` / `1` |
| NSGlobalDomain NSTableViewDefaultSizeMode | `1` |
| NSGlobalDomain _HIHideMenuBar | `0` |
| NSGlobalDomain TISRomanSwitchState | `1` |
| NSGlobalDomain com.apple.scrollwheel.scaling | `1.7` |
| NSGlobalDomain AppleMenuBarVisibleInFullscreen | `1` |
| NSGlobalDomain com.apple.sound.uiaudio.enabled | `0` |
| NSGlobalDomain UIPreferredContentSizeCategoryName | `UICTContentSizeCategoryXS` |
| .GlobalPreferences com.apple.mouse.scaling | `2.5` |
| HIToolbox AppleFnUsageType | `2` |
| dock autohide / orientation / tilesize / magnification / largesize | `1` / `left` / `16` / `1` / `71` |
| dock show-recents / mru-spaces / expose-group-apps / wvous-br-corner | `0` / `0` / `1` / `14` |
| finder FXPreferredViewStyle / NewWindowTarget / ShowPathbar | `clmv` / `PfAF` / `1` |
| finder ShowExternalHardDrivesOnDesktop / ShowHardDrivesOnDesktop / ShowRemovableMediaOnDesktop / ShowSidebar | `1` / `0` / `1` / `0` |
| 両 trackpad domain: Clicking / TrackpadRightClick / TrackpadThreeFingerDrag | `1` / `1` / `1` |
| 両 trackpad domain: ThreeFinger Horiz / Vert / Tap | `0` / `0` / `0` |
| 両 trackpad domain: FourFinger Horiz / Vert / Pinch | `2` / `2` / `2` |
| clock ShowSeconds / ShowDayOfWeek / ShowAMPM / ShowDate | `1` / `1` / `1` / `0` |
| controlcenter BatteryShowPercentage / Bluetooth / Display | `1` / `24` / `24` |
| WindowManager EnableTiledWindowMargins | `0` |
| spaces spans-displays | `0` |
| loginwindow GuestEnabled | `0` |

1 つでも不一致、または `does not exist` が出たら、その key と値を報告して停止する（宣言の書き間違いか nix-darwin 側の domain 違い）。

- [ ] Step 6: **[ユーザー実行]** `activateSettings -u` の効果判定と外す判断

宣言値は現在値と同一なので「値が変わった」ことでは効果を測れない。次の基準で判断する。

1. Step 4 の switch 出力に `warning: activateSettings -u failed (ignored)` が **出た** → 効いていない。外す（下記）
2. switch 直後（ログアウト前）にメニューバー・Dock・Finder に再描画の乱れや Finder の再起動など副作用が出た → 外す
3. 上記どちらも無い → 残す（害が無く、キーリピート・外観・時計・Finder の即時反映が見込める）

任意の追加確認: システム設定 > キーボードで「キーのリピート速度」を一段変え、Step 4 の switch をもう一度実行する。ログアウト無しに Terminal でのキーリピート速度が宣言値（速い側）に戻れば効いている。

外す場合は `/Users/mac83009105/.local/share/chezmoi/nix/darwin/default.nix` の 16〜22 行目（`# defaults write 後に...` のコメント 2 行から `'';` まで）を削除し、Step 3 の build → Step 4 の switch をやり直してから

```sh
git -C /Users/mac83009105/.local/share/chezmoi add nix/darwin/default.nix
git -C /Users/mac83009105/.local/share/chezmoi commit -m "fix(nix): 効果の無い activateSettings の呼び出しを削除"
```

でコミットする（Step 7 のコミットとは分ける）。

- [ ] Step 7: コミット

```sh
git -C /Users/mac83009105/.local/share/chezmoi diff --stat nix/darwin/defaults.nix
git -C /Users/mac83009105/.local/share/chezmoi add nix/darwin/defaults.nix
git -C /Users/mac83009105/.local/share/chezmoi commit -m "feat(nix): macOS の system.defaults を宣言"
```

- [ ] Step 8: **[ユーザー実行]** ログアウト / ログインして体感確認

Apple メニュー > ログアウト → 再ログイン後、Caps Lock で IME が切り替わること、3 本指ドラッグとタップでクリックが効くこと、Dock が左・自動非表示であることを確認する（設計書 §7「反映タイミング」で ByHost 側のキーはログアウト後に確定する）。

---

### Task 7: `homebrew.nix` を投入して Homebrew の状態を宣言に収束させる（設計書 §4.5, §6 手順 5, §8.1）

**Files:**
- Modify: `/Users/mac83009105/.local/share/chezmoi/nix/darwin/homebrew.nix`（Task 5 の 3 行の空モジュールを全文置換）
- Create（リポジトリ外・一時）: `${TMPDIR:-/tmp}/Brewfile`
- Test: 生成 Brewfile の内容、`brew bundle cleanup` の dry-run、switch 後の `brew tap` / `brew leaves` / `brew list --cask` / `brew services list`

**Interfaces:**
- Consumes: Task 5 の `darwinConfigurations.BNMAC00101`、`config.system.primaryUser`（`homebrew.user` の既定値になる）
- Produces: `config.homebrew.brewfile`（生成 Brewfile の文字列。`nix eval --raw` で取り出せる）、`config.homebrew.enable = true`、switch 時に `brew bundle --file=<store の Brewfile> --no-upgrade --force-cleanup` が `mac83009105` として実行される（`modules/homebrew.nix` の `brewBundleCmd` で確認済み）

**前提の事実（2026-09-14 実測）:**
- `brew tap` は 7 つ: `daipeihust/tap` `felixkratz/formulae` `idoavrah/homebrew` `jesseduffield/lazydocker` `manaflow-ai/cmux` `nikitabobko/tap` `oven-sh/bun`。宣言しない 2 つ（`idoavrah/homebrew`、`manaflow-ai/cmux`）からインストールされた formula / cask は無い（`cmux` は公式 cask、`brew info --cask cmux` で確認）
- `brew tap-info daipeihust/tap` は `Untrusted`。未信頼 tap の formula（im-select、borders）は `brew leaves` と `brew services list` から黙って落ちる。信頼付与は `brew trust --tap <tap>`（設定は `~/.homebrew/trust.json`）
- borders は `launchctl list` に `homebrew.mxcl.borders` として常駐中。`brew services list` には未信頼のため出ていない

- [ ] Step 1: RED — homebrew が無効で Brewfile が空であることを確認

```sh
/nix/var/nix/profiles/default/bin/nix eval --json /Users/mac83009105/.local/share/chezmoi/nix#darwinConfigurations.BNMAC00101.config.homebrew.enable
/nix/var/nix/profiles/default/bin/nix eval --raw /Users/mac83009105/.local/share/chezmoi/nix#darwinConfigurations.BNMAC00101.config.homebrew.brewfile | grep -c '^brew '
```

期待出力: `false` と `0`

- [ ] Step 2: `nix/darwin/homebrew.nix` を全文置換

`/Users/mac83009105/.local/share/chezmoi/nix/darwin/homebrew.nix` の全文:

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

- [ ] Step 3: build して Brewfile を取り出し、件数を確認（実行者）

```sh
/nix/var/nix/profiles/default/bin/nix build --no-link --print-out-paths /Users/mac83009105/.local/share/chezmoi/nix#darwinConfigurations.BNMAC00101.system
/nix/var/nix/profiles/default/bin/nix eval --raw /Users/mac83009105/.local/share/chezmoi/nix#darwinConfigurations.BNMAC00101.config.homebrew.brewfile > "${TMPDIR:-/tmp}/Brewfile"
cat "${TMPDIR:-/tmp}/Brewfile"
grep -c '^tap ' "${TMPDIR:-/tmp}/Brewfile"
grep -c '^brew ' "${TMPDIR:-/tmp}/Brewfile"
grep -c '^cask ' "${TMPDIR:-/tmp}/Brewfile"
grep -c 'trusted: true' "${TMPDIR:-/tmp}/Brewfile"
grep -c 'https://github.com/FelixKratz/homebrew-formulae' "${TMPDIR:-/tmp}/Brewfile"
grep -c 'start_service: true' "${TMPDIR:-/tmp}/Brewfile"
grep -c 'link: true' "${TMPDIR:-/tmp}/Brewfile"
```

期待出力（順に）: store パス 1 行 / Brewfile 本文 / `5` / `36` / `7` / `5` / `1` / `1` / `2`

- [ ] Step 4: **[ユーザー実行]** 宣言する第三者 tap を先に信頼させる（dry-run を正確にするため。switch でも `trusted: true` により同じ状態になる）

```sh
brew trust --tap daipeihust/tap felixkratz/formulae jesseduffield/lazydocker nikitabobko/tap oven-sh/bun
brew tap-info daipeihust/tap felixkratz/formulae nikitabobko/tap | grep -c '^Trusted'
```

期待出力: 2 つ目のコマンドが `3`

- [ ] Step 5: cleanup の dry-run で削除候補を目視（実行者。`--force` を付けないので何も削除されない）

```sh
/opt/homebrew/bin/brew bundle cleanup --file="${TMPDIR:-/tmp}/Brewfile"
/opt/homebrew/bin/brew leaves | grep -E 'im-select|borders'
```

期待出力:
- 1 つ目: untap 候補として `idoavrah/homebrew` と `manaflow-ai/cmux` の 2 つだけが出る。formula・cask の削除候補は **0 件**
- 2 つ目: `daipeihust/tap/im-select` と `felixkratz/formulae/borders` の 2 行（Step 4 の信頼付与で `brew leaves` に現れるようになった証拠）

**formula または cask が 1 つでも削除候補に出た場合は Step 6 に進まず、その名前を報告して停止する。** 宣言に足すか削除を受け入れるかはユーザーの判断。

- [ ] Step 6: **[ユーザー実行]** switch（ここで実際に untap と cleanup が走る）

```sh
sudo darwin-rebuild switch --flake /Users/mac83009105/.local/share/chezmoi/nix
```

期待出力: `Homebrew bundle...` の後に `brew bundle` のログ（`Using bat` ... のような各項目の行、`Untapping idoavrah/homebrew`、`Untapping manaflow-ai/cmux`）が流れ、エラー無く終了する。`upgrade = false` なので `borders 1.8.4 → 1.9.0` のような更新は **行われない**。

- [ ] Step 7: GREEN — Homebrew の状態が宣言と一致することを確認（実行者。sudo 不要）

```sh
/opt/homebrew/bin/brew tap
/opt/homebrew/bin/brew tap | wc -l
/opt/homebrew/bin/brew list --cask | tr '\n' ' '; echo
/opt/homebrew/bin/brew list --cask | wc -l
/opt/homebrew/bin/brew leaves | tr '\n' ' '; echo
/opt/homebrew/bin/brew services list | grep borders
launchctl list | grep -c homebrew.mxcl.borders
/opt/homebrew/bin/brew list --formula | grep -cx -e im-select -e borders -e lazydocker -e bun
```

期待出力:
- `brew tap`: `daipeihust/tap` `felixkratz/formulae` `jesseduffield/lazydocker` `nikitabobko/tap` `oven-sh/bun` の 5 行（`idoavrah/homebrew` と `manaflow-ai/cmux` が消えている）、`wc -l` は `5`
- casks: `aerospace cmux dockdoor font-fira-code-nerd-font gcloud-cli ghostty wezterm`、`wc -l` は `7`
- `brew leaves`: Task 開始前の 33 個（bat chezmoi coreutils direnv expat fd ffmpeg-full fzf gh ghq git go herdr hunk imagemagick-full jesseduffield/lazydocker/lazydocker jq lazygit lazysql lsd neovim nkf nodebrew oven-sh/bun/bun poppler redis resvg ripgrep sevenzip tmux tree-sitter-cli yazi zoxide）に `daipeihust/tap/im-select` と `felixkratz/formulae/borders` が加わった 35 個。減っているものが無いこと（`tree-sitter` は neovim の依存として残るため leaves には出ない。それで正しい）
- `brew services list | grep borders`: `borders  started  mac83009105 ...` の 1 行
- `1`
- `4`

- [ ] Step 8: コミット

```sh
git -C /Users/mac83009105/.local/share/chezmoi diff --stat nix/darwin/homebrew.nix
git -C /Users/mac83009105/.local/share/chezmoi add nix/darwin/homebrew.nix
git -C /Users/mac83009105/.local/share/chezmoi commit -m "feat(nix): Homebrew の tap と formula と cask を宣言"
```

---

### Task 8: 世代のロールバック往復を確認（設計書 §6 手順 6, §7）

**Files:**
- Create / Modify: なし
- Test: `darwin-rebuild --list-generations`、`readlink /run/current-system`

**Interfaces:**
- Consumes: Task 5〜7 が作った system profile の世代 1〜3（`/nix/var/nix/profiles/system`）
- Produces: なし（ロールバック経路が生きていることの確認のみ）

- [ ] Step 1: 現在の世代を記録（実行者。sudo 不要）

```sh
/run/current-system/sw/bin/darwin-rebuild --list-generations
readlink /run/current-system
readlink /nix/var/nix/profiles/system-2-link
```

期待出力:
- 世代 `1` `2` `3` の 3 行があり、`3` に `(current)` が付く
- `/run/current-system` は Task 7 Step 3 の build が表示した store パス
- `system-2-link` は Task 6 の store パス（Task 7 の値と異なる。以降「世代 2 のパス」と呼ぶ）

Task 6 Step 6 で activateSettings を外して再 switch した場合は世代が 1 つ多く（`1`〜`4`、current は `4`）、「世代 2」は `system-3-link` に読み替える。以降の Step も同様に「current の 1 つ前の世代」で読む。

- [ ] Step 2: **[ユーザー実行]** 1 世代戻す

```sh
sudo darwin-rebuild --rollback
```

期待出力: 世代 2 の activation ログ（`user defaults...` `restarting Dock...`）が流れ、エラー無く終了する。世代 2 は `homebrew.enable = false` なので `Homebrew bundle...` は出ない。

- [ ] Step 3: 戻ったことを確認（実行者）

```sh
/run/current-system/sw/bin/darwin-rebuild --list-generations
readlink /run/current-system
/opt/homebrew/bin/brew tap | wc -l
```

期待出力:
- `2` に `(current)` が付く
- `/run/current-system` = 世代 2 のパス
- `5`（ロールバックは brew の状態を戻さない。設計書 §7「ロールバックの限界」どおり）

- [ ] Step 4: **[ユーザー実行]** 再 switch で最新に戻す

```sh
sudo darwin-rebuild switch --flake /Users/mac83009105/.local/share/chezmoi/nix
```

期待出力: 世代 3 と同じ内容のビルド（Task 7 のコミットで `configurationRevision` が変わっているため store パスは新規）→ activation（`Homebrew bundle...` を含む）がエラー無く終了する。

- [ ] Step 5: GREEN — 往復の完了を確認（実行者）

```sh
/run/current-system/sw/bin/darwin-rebuild --list-generations
readlink /run/current-system
/run/current-system/sw/bin/darwin-version --configuration-revision
git -C /Users/mac83009105/.local/share/chezmoi rev-parse HEAD
/opt/homebrew/bin/brew tap | wc -l
git -C /Users/mac83009105/.local/share/chezmoi status --short
```

期待出力:
- 世代 `4` が追加され `(current)` が付く
- `/run/current-system` は世代 2 のパスと **異なる**
- `--configuration-revision` = `<rev-parse HEAD>-dirty`
- `5`
- git status は共通ルール 4 の 2 行のみ（Phase 1 の全変更がコミット済み）

- [ ] Step 6: コミット — **なし**（リポジトリに変更が無い）

---

## 完了条件（全タスク後）

- `git -C /Users/mac83009105/.local/share/chezmoi log --oneline -7` に次の 6 コミットが新しい順に並ぶ（Task 6 Step 6 で activateSettings を外した場合は `fix(nix): ...` が 1 つ増える）:
  `feat(nix): Homebrew の tap と formula と cask を宣言` / `feat(nix): macOS の system.defaults を宣言` / `feat(nix): nix-darwin の flake 骨格を追加` / `fix(zsh): PATH リセット行が既存の PATH を消さないようにする` / `chore(zsh): ローカルの mise 初期化行を chezmoi に同期` / `chore(chezmoi): nix と docs と README.md を配置対象から除外`
- push と PR 作成はループ外でユーザーが行う

---

## 実行記録（2026-09-15）

全 8 タスクを完了。コミットは計画の 6 に加えて `chore(nix): 使わなくなった cmux を cask 宣言から外す` の 1 つ（ユーザー判断でスコープ追加）。
計画と実際の差分を残す。次に同種の作業をするときはここを先に読む。

### 計画から外れた点

| 箇所 | 計画 | 実際 |
|---|---|---|
| 共通ルール 2 | `[ユーザー実行]` は `! <command>` で実行 | **`!` 経由は対話も sudo のパスワード入力もできない**（Determinate インストーラが `Unable to run interactively` で停止）。sudo を伴う手順はすべてユーザーの通常ターミナルで実行した |
| Task 3 Step 4 | `/opt/homebrew/bin` の出現数 = 1 | 4。実行者環境の PATH に既に含まれていたため重複した。動作に影響なし |
| Task 4 Step 3 | `/etc/zshenv` のハッシュ `d07015be…` | `4e8f7cb9…`（nix-darwin の既知リストに「experimental official Nix installer 2.33.3」として登録済み）。`check` は通った |
| Task 5 Step 7 | 最後の行が `ok` | 正しかった。`check` は activate を `checkActivation=1` で呼び、`ok` を出して終了する（レビュー時に「exit 0」へ緩めたのは不要だった） |
| Task 5 Step 8 | `nix run nix-darwin/master#darwin-rebuild -- switch` で世代 1 が作られる | **activation は完走したが `/nix/var/nix/profiles/system` が作られなかった**（gcroot も無し）。原因は未確定（当時の出力を保存していなかった）。`sudo nix-env -p /nix/var/nix/profiles/system --set <store path>` を手動実行して世代 1 を作成。以後の `sudo darwin-rebuild switch`（system 内蔵版）は正常に世代を作った |
| Task 5 Step 9 | `zsh -ic` で `darwin-rebuild` が見える | 実行者環境には `__NIX_DARWIN_SET_ENVIRONMENT_DONE=1` が入っており子 zsh が `/etc/zshenv` の PATH 設定をスキップするため見えない。`env -u __NIX_DARWIN_SET_ENVIRONMENT_DONE -u __ETC_ZSHENV_SOURCED zsh -lic` で新規ログインシェル相当を再現して確認した |
| Task 6 Step 8 | Task 7 の前にログアウト | この Claude Code セッションも終了するため Task 8 の後に回した |
| Task 7 Step 2 | brew 36 本 | **38 本**。`whisper.cpp` と `sdl2-compat` を追加。ffmpeg-full の依存だが、formula 側が旧名 `whisper-cpp` / エイリアス `sdl2` で参照しており `brew bundle cleanup` がリネーム／エイリアスを解決できず削除候補にしたため（dry-run で検出、停止条件どおりユーザーに確認して追加） |
| Task 7 Step 4 | `brew trust` は `[ユーザー実行]` | sudo 不要で実行者が実行できた |
| Task 7 Step 5→6 | dry-run と実 cleanup は同じ結果 | 実 cleanup は dry-run に無かった `json-c` `qrencode` `llama.cpp` の削除を試みて brew 自身が拒否（依存されているため）。実害なし。`Uninstalled 3 formulae` の表示は誤りで 3 つとも残っている |
| Task 7 Step 6 | `Untapping idoavrah/homebrew` `Untapping manaflow-ai/cmux` | `manaflow-ai/cmux` の untap で `Refusing to load cask manaflow-ai/cmux/cmux from untrusted tap` が出て untap フェーズが止まり、2 つとも残った。`idoavrah/homebrew` は手動 `brew untap` で成功。`manaflow-ai/cmux` は `brew trust` → `brew untap` でも「インストール済み cask がある」と拒否 |
| Task 7 Step 6 | `upgrade = false` なので更新なし | **ffmpeg-full が 8.1 → 9.0.1_1 に更新された**。`sdl2` → `sdl2-compat` のリネーム keg 移行に伴い brew が依存元を再インストールしたため。`--no-upgrade` は Brewfile 記載物の upgrade を抑止するだけで、この動作は抑止しない |
| Task 7 Step 7 | casks 7 | ユーザーが「cmux は使わない」と判断 → 宣言から外し（`81616d4`）、Task 8 Step 4 の switch で cleanup が削除。casks は **6** |
| Task 8 Step 1 | `darwin-rebuild --list-generations` | root 権限が必要（`system.lock` の作成）。`ls -la /nix/var/nix/profiles/` で代替 |
| Task 8 | 世代 1〜3、往復で 4 | 実際も 1〜4（1 = 手動作成の骨格、2 = defaults、3 = homebrew、4 = 再 switch で cmux 削除） |

### 二度と踏まないための注意

- **`brew untap --force <tap>` は、その tap に帰属していると記録された cask を本体ごとアンインストールする。** cmux がこれで一度消え、`brew install --cask cmux` で復旧した（その後ユーザー判断で削除）。「--force は untap だけ」ではない
- `brew bundle check` は `--no-upgrade` を付けないと outdated な formula を「未充足」と報告する。nix-darwin と同じ条件で見るなら必ず付ける
- 初回 switch の直後に `ls -la /nix/var/nix/profiles/system` を確認する。無ければ `sudo nix-env -p /nix/var/nix/profiles/system --set $(readlink /run/current-system)` で作る
- dry-run に出た `libtiff, webp` の循環依存 warning は ffmpeg 更新後の keg tab の古さによるもの。brew の案内どおり再インストールすれば消える（Phase 1 対象外）
