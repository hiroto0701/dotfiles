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
