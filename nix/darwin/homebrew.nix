{ lib, username, ... }:
{
  # brew install で共有ライブラリ（tree-sitter など）だけが上がり、それを使う formula が
  # 古い dylib を参照したまま起動できなくなることがある。Homebrew の dependents check は
  # 当てにならなかったため、switch のたびに全 formula を検査して警告だけ出す（約1秒）。
  # activation script は set -e で動くため、検査の失敗で activation を止めない
  system.activationScripts.postActivation.text = lib.mkAfter ''
    echo "checking Homebrew linkage..." >&2
    broken=$(sudo --user=${username} --set-home -- /bin/bash -c \
      '/opt/homebrew/bin/brew linkage --test $(/opt/homebrew/bin/brew list --formula) 2>&1' \
      | /usr/bin/awk '/^==> Checking .* linkage/ { f = $3 } /^(Broken|Missing)/ { print f }' \
      | /usr/bin/sort -u | /usr/bin/tr '\n' ' ') || true
    if [ -n "$broken" ]; then
      echo >&2 "warning: Homebrew formulae with broken linkage: $broken"
      echo >&2 "warning: fix with: brew upgrade $broken (or brew reinstall if not outdated)"
    fi
  '';

  homebrew = {
    enable = true;                        # Homebrew 本体は nix-homebrew が入れる (flake.nix)。ここは formula / cask の宣言
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
      "bat" "coreutils" "direnv" "expat" "fd"
      { name = "ffmpeg-full"; link = true; }
      "fzf" "gh" "ghq" "git" "go" "herdr" "hunk"
      { name = "imagemagick-full"; link = true; }
      "jq" "lazygit" "lazysql" "lsd" "neovim" "nkf" "nodebrew" "poppler" "redis"
      "resvg" "ripgrep" "sevenzip" "tmux" "tree-sitter" "tree-sitter-cli" "yazi" "zoxide"
      # ffmpeg-full の依存。formula 側は旧名 whisper-cpp / エイリアス sdl2 で参照しており、
      # brew bundle cleanup がリネーム/エイリアスを解決できず削除候補にするため明示する
      "whisper.cpp" "sdl2-compat"
      "daipeihust/tap/im-select"
      { name = "felixkratz/formulae/borders"; start_service = true; }
      "jesseduffield/lazydocker/lazydocker"
      "oven-sh/bun/bun"
    ];

    casks = [
      "nikitabobko/tap/aerospace"
      "dockdoor"
      "font-fira-code-nerd-font"
      "gcloud-cli"
      "ghostty"
      "wezterm"
    ];
  };
}
