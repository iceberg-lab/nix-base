{
  description = "Base quality-of-life setup for remote Linux machines";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, home-manager, ... }:
    let
      supportedSystems = [ "x86_64-linux" "aarch64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;

      mkHome = { system, username, gitName, gitEmail }: home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.${system};
        modules = [
          ./home.nix
          {
            home.username = username;
            home.homeDirectory = "/home/${username}";
            hm-base.gitName = gitName;
            hm-base.gitEmail = gitEmail;
          }
        ];
      };
    in
    {
      lib.mkHome = mkHome;

      # Import as a module for composing with other flakes:
      #   modules = [ hm-base.homeModules.default ];
      homeModules.default = ./home.nix;

      packages = forAllSystems (system: {
        default = home-manager.packages.${system}.home-manager;
      });
    };
}
