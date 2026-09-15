{
  description = "nix-darwin configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:nix-darwin/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nix-homebrew.url = "github:zhaofengli/nix-homebrew";
    # Homebrew 本体のソース。nix-homebrew 既定の 6.0.22 ではなく現行の 7.0.1 に固定する
    brew-src = { url = "github:Homebrew/brew/7.0.1"; flake = false; };
    nix-homebrew.inputs.brew-src.follows = "brew-src";
  };

  outputs = { self, nix-darwin, nixpkgs, home-manager, nix-homebrew, brew-src }:
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
                # follows だけだと nix-homebrew は自分の flake.lock から "6.0.22" のラベルを付けるため、
                # name / version も 7.0.1 で揃える。`brew --version` には出ないが、
                # store パス名 `brew-7.0.1-patched` で確認できる
                package = brew-src // { name = "brew-7.0.1"; version = "7.0.1"; };
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
