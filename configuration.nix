{ config, pkgs, inputs, ... }:

{
  imports =
    [
      ./hardware-configuration.nix
      ./flatpaks.nix
      #./kdefix.nix
      ./sunshine.nix
    ];

  # --- NixOS Garbage Collection & nh ---
  programs.nh = {
    enable = true;
    clean.enable = true;
    clean.extraArgs = "--keep-since 4d --keep 3";
    flake = "/home/sungold/nixos-config";
  };

  fileSystems."/mnt/snvme" = {
    device = "/dev/disk/by-label/SNVME";
    fsType = "btrfs";
    options = [ "compress=zstd" "noatime" "nofail"];
  };

  virtualisation.docker.enable = true;
  virtualisation.libvirtd.enable = true;
  programs.virt-manager.enable = true;

  services.tailscale.enable = true;

  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
    };
  };

  nix.settings = {
    substituters = [ "https://attic.xuyh0120.win/lantian" ]; # CachyOS kernel binary cache
    trusted-public-keys = [ "lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc=" ];
  };

  boot.kernel.sysctl = {
    "kernel.sysrq" = 1;
    "net.core.default_qdisc" = "fq";
    "net.ipv4.tcp_congestion_control" = "bbr";
  };

  boot = {
    # Disable standard systemd-boot to use Lanzaboote
    loader.systemd-boot.enable = false;
    loader.efi.canTouchEfiVariables = true;
    loader.timeout = 0;                  # Skip menu (hold Space to show)
    loader.systemd-boot.editor = false;  # Enable to use cmdline editing

    lanzaboote = {
      enable = true;
      pkiBundle = "/var/lib/sbctl";
    };

    kernelPackages = pkgs.cachyosKernels.linuxPackages-cachyos-latest-lto-x86_64-v3;
    kernelModules = [ "ntsync" ];
    consoleLogLevel = 0;
    initrd.verbose = false;
    initrd.kernelModules = [ "amdgpu" ];
    initrd.systemd.enable = true;  # Needed for TPM Unlock
    initrd.availableKernelModules = [ "tpm_crb" "tpm_tis" ]; # AMD fTPM

    plymouth = {
      enable = true;
      #theme = "bgrt";
    };

    kernelParams = [
      "quiet"
      "splash"
      "boot.consoleLogLevel=0"
      "rd.systemd.show_status=false"
      "rd.udev.log_level=3"
      "udev.log_priority=3"
      "zswap.enabled=1"
      "zswap.compressor=zstd"
      "zswap.zpool=zsmalloc"
    ];
  };

  hardware.amdgpu.overdrive.enable = true;

  hardware.bluetooth.enable = true;
  networking.hostName = "zeus";
  networking.networkmanager = {
    enable = true;
    plugins = with pkgs; [ networkmanager-openconnect ];
  };

  programs.kdeconnect.enable = true;

  networking.firewall = {
    enable = true;
    trustedInterfaces = [ "virbr0" ];
  };

  time.timeZone = "America/Toronto";
  i18n.defaultLocale = "en_CA.UTF-8";

  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;
  services.displayManager.defaultSession = "aerothemeplasma";
  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  programs.aeroshell = {
    enable = true;
    fonts.segoe.enable = true;
    polkit.enable = true;
    sessions.x11.enable = false;
    aerothemeplasma = {
      enable = true;
      sddm.enable = true;
      plymouth.enable = true;
    };
  };

  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  users.users.sungold = {
    isNormalUser = true;
    description = "Suraaj Vashisht";
    extraGroups = [ "networkmanager" "wheel" "docker" "gamemode" "plugdev" "libvirtd" "input" ];
  };

  users.groups.plugdev = {};

  nixpkgs.config.allowUnfree = true;
  environment.systemPackages = with pkgs; [
    vim
    wget
    git
    sbctl
    vulkan-tools
    lm_sensors
    lsof
    unrar
    amdgpu_top
    e2fsprogs
    rivalcfg
    usbutils
    pciutils
    freetype
    dnsmasq
    bind
    whois
    mesa-demos
    _7zip-zstd
    kdePackages.partitionmanager
    gptfdisk
    parted
    ffmpeg
    virtiofsd
    ryzenadj

    inputs.jovian-nixos.legacyPackages.${pkgs.stdenv.hostPlatform.system}.dmemcg-booster
    inputs.jovian-nixos.legacyPackages.${pkgs.stdenv.hostPlatform.system}.plasma-foreground-booster
  ];

  # For keeb
  hardware.ckb-next = {
    enable = true;
    package = pkgs.ckb-next.overrideAttrs (old: {
      cmakeFlags = (old.cmakeFlags or [ ]) ++ [ "-DUSE_DBUS_MENU=0" ];
    });
  };

  services.udev.packages = [ pkgs.rivalcfg ];

  # For onlyoffice
  fonts.packages = with pkgs; [
    corefonts
  ];

  programs.appimage = {
    enable = true;
    binfmt = true;
  };

  services.tuned.enable = true;
  programs.gamemode.enable = true;
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    package = pkgs.steam.override {
      extraProfile = ''
        # Allows WiVRn to be detected by Steam games
        export PRESSURE_VESSEL_IMPORT_OPENXR_1_RUNTIMES=1
      '';
    };
  };

  services.wivrn = {
    enable = true;
    openFirewall = true;
    package = inputs.nixpkgs-small.legacyPackages.${pkgs.stdenv.hostPlatform.system}.wivrn;
  };



  # ZSWAP Device
  fileSystems."/swap" = {
    device = "/dev/disk/by-uuid/0ae15a10-33cf-4d69-a3df-b8b635dd902e";
    fsType = "btrfs";
    options = [ "subvol=@swap" "noatime" ];
  };

  swapDevices = [ {
    device = "/swap/swapfile";
  } ];

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    # Needed for some ROCm to see the GPU
    extraPackages = with pkgs; [
      rocmPackages.clr.icd
    ];
  };

  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    stdenv.cc.cc
    zlib
    fuse3
    icu
    nss
    openssl
    curl
    expat
  ];

  services.lact.enable = true;

  # dmemcg VRAM Optimization
  systemd.packages = [
    inputs.jovian-nixos.legacyPackages.${pkgs.stdenv.hostPlatform.system}.dmemcg-booster
    inputs.jovian-nixos.legacyPackages.${pkgs.stdenv.hostPlatform.system}.plasma-foreground-booster
  ];

  systemd.services.dmemcg-booster-system = {
    wantedBy = [ "multi-user.target" ];
  };

  systemd.user.services.dmemcg-booster-user = {
    wantedBy = [ "graphical-session-pre.target" ];
  };

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  system.stateVersion = "25.05";
}
