{
  description = "NixOS Configuration for Dell G5";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    nix-cachyos-kernel.url = "github:xddxdd/nix-cachyos-kernel/release";

    swift-flake.url = "github:timothyklim/swift-flake";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    lanzaboote = {
      url = "github:nix-community/lanzaboote/v0.4.3";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-flatpak.url = "github:gmodena/nix-flatpak/?ref=latest";

    zen-browser.url = "github:0xc000022070/zen-browser-flake";

    jovian-nixos.url = "github:Jovian-Experiments/Jovian-NixOS/development";

    opencode.url = "github:anomalyco/opencode/dev";
  };

  outputs = { self, nixpkgs, nix-cachyos-kernel, home-manager, lanzaboote, nix-flatpak, swift-flake, jovian-nixos, opencode, ... }@inputs: {
    nixosConfigurations.zeus = nixpkgs.lib.nixosSystem {
      specialArgs = { inherit inputs; };
      modules = [
        ./configuration.nix

        {
          nixpkgs.overlays = [
            nix-cachyos-kernel.overlays.pinned
            (import ./soulver-overlay.nix { inherit swift-flake; })
            opencode.overlays.default
          ];
        }
        
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.extraSpecialArgs = {inherit inputs;};
          home-manager.users.sungold = import ./home.nix;
        }

        lanzaboote.nixosModules.lanzaboote

        nix-flatpak.nixosModules.nix-flatpak
      ];
    };
  };
}
