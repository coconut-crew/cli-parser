{
  inputs = {
    roblox-development-flake.url = "github:nnullcolumn/roblox-development-flake";
    codex-cli.url = "github:sadjow/codex-cli-nix";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    {
      nixpkgs,
      roblox-development-flake,
      codex-cli,
      ...
    }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };

      # evil shell script which is actually just bash LOL
      nnull_shell = pkgs.writeShellScriptBin "nnull-shell" ''
        bash
      '';

      nnull_packages = pkgs: [
        nnull_shell
        codex-cli.packages.${pkgs.stdenv.hostPlatform.system}.default # slop
        pkgs.fish # :3
        pkgs.dbus # pesde
      ];

      robloxShells = roblox-development-flake.devShells.${system};
    in
    {
      devShells.${system} = {
        simple = robloxShells.simple;
        nnull =
          (roblox-development-flake.lib.fhs {
            overrides = old: {
              targetPkgs = pkgs: nnull_packages (pkgs) ++ old.targetPkgs (pkgs);

              privateTmp = false;

              runScript = (old.runScript or "") + ''
                nnull-shell
              '';
            };
          }).env;
        fish = robloxShells.fish;

        default = robloxShells.fish;
      };
    };
}
