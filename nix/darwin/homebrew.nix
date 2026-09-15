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
      "cmux"
      "dockdoor"
      "font-fira-code-nerd-font"
      "gcloud-cli"
      "ghostty"
      "wezterm"
    ];
  };
}
