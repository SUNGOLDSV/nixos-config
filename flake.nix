{
  description = "NixOS Configuration for Dell G5";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-master.url = "github:nixos/nixpkgs/master";
    nixpkgs-small.url = "github:nixos/nixpkgs/nixos-unstable-small";

    nix-cachyos-kernel.url = "github:xddxdd/nix-cachyos-kernel/release";

    #swift-flake.url = "github:timothyklim/swift-flake";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    lanzaboote = {
      url = "github:nix-community/lanzaboote";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-flatpak.url = "github:gmodena/nix-flatpak/?ref=latest";

    zen-browser.url = "github:0xc000022070/zen-browser-flake";

    jovian-nixos.url = "github:Jovian-Experiments/Jovian-NixOS/development";

    opencode.url = "github:anomalyco/opencode/dev";

    aerothemeplasma-nix = {
      url = "github:nyakase/aerothemeplasma-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nix-cachyos-kernel, home-manager, lanzaboote, nix-flatpak, jovian-nixos, opencode, aerothemeplasma-nix, ... }@inputs: {
    nixosConfigurations.zeus = nixpkgs.lib.nixosSystem {
      specialArgs = { inherit inputs; };
      modules = [
        ./configuration.nix

        {
          nixpkgs.overlays = [
            nix-cachyos-kernel.overlays.pinned
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

        aerothemeplasma-nix.nixosModules.aerothemeplasma-nix
      ];
    };
  };
}
