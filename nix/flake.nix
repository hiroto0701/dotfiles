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
