{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ./flatpaks.nix
      #./kdefix.nix
    ];

  # --- NixOS Garbage Collection ---
  nix.gc = { 
    automatic = true;
    persistent = true;
    dates = "05:00:00";
    options = "--delete-older-than 30d";
  };

  # --- SNVME Mount ---
  fileSystems."/mnt/snvme" = {
    device = "/dev/disk/by-label/SNVME";
    fsType = "btrfs";
    options = [ "compress=zstd" "noatime" "nofail"];
  };

  # --- Virtualization ---
  virtualisation.docker.enable = true;
  virtualisation.libvirtd.enable = true;
  programs.virt-manager.enable = true;

  # --- SSH ACCESS ---
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
    };
  };

  # --- BOOTLOADER ---
  nix.settings = {
    substituters = [ "https://attic.xuyh0120.win/lantian" ]; # CachyOS kernel binary cache
    trusted-public-keys = [ "lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc=" ];
  };
  boot.kernel.sysctl."kernel.sysrq" = 1; # REISUB Magic SysRq
  boot = {
    # Disable standard systemd-boot to use Lanzaboote
    loader.systemd-boot.enable = false;
    loader.efi.canTouchEfiVariables = true;
    loader.timeout = 0;                  # Skip menu (hold Space to show)
    loader.systemd-boot.editor = false;  # Enable to use cmdline editing

    # Enable Lanzaboote
    lanzaboote = {
      enable = true;
      pkiBundle = "/var/lib/sbctl";
    };

    # --- Initrd & Kernel ---
    kernelPackages = pkgs.cachyosKernels.linuxPackages-cachyos-latest;
    kernelModules = [ "ntsync" ];
    consoleLogLevel = 0;
    initrd.verbose = false;
    initrd.kernelModules = [ "amdgpu" ];
    initrd.systemd.enable = true;  # Needed for TPM Unlock
    initrd.availableKernelModules = [ "tpm_crb" "tpm_tis" ]; # AMD fTPM

    # --- Silent Boot ---
    plymouth = {
      enable = true;
      theme = "bgrt";
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

  # --- NETWORKING ---
  hardware.bluetooth.enable = true;
  networking.hostName = "zeus";
  networking.networkmanager = {
    enable = true;
    # GUI plugin for OpenConnect
    plugins = with pkgs; [ networkmanager-openconnect ];
  };
  # --- KDE CONNECT ---
  programs.kdeconnect.enable = true;

  networking.firewall = {
    enable = true;
    trustedInterfaces = [ "virbr0" ];
    allowedTCPPortRanges = [
      { from = 1714; to = 1764; }
    ];
    allowedUDPPortRanges = [
      { from = 1714; to = 1764; }
    ];
  };
  # --- TIME & LOCALE ---
  time.timeZone = "America/Toronto";
  i18n.defaultLocale = "en_CA.UTF-8";

  # --- DESKTOP (KDE Plasma) ---
  services.displayManager.plasma-login-manager.enable = true;
  services.desktopManager.plasma6.enable = true;
  environment.sessionVariables.NIXOS_OZONE_WL = "1"; # Enable wayland for ozone/electron

  # --- AUDIO (Pipewire) ---
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # --- USER ACCOUNT ---
  users.users.sungold = {
    isNormalUser = true;
    description = "Suraaj Vashisht";
    extraGroups = [ "networkmanager" "wheel" "docker" "gamemode" "plugdev" "libvirtd" ];
  };

  users.groups.plugdev = {};

  # --- SYSTEM PACKAGES ---
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
    freetype
    dnsmasq
    bind
    whois
    mesa-demos
    p7zip
    kdePackages.partitionmanager
    gptfdisk
    parted
    ffmpeg
  ];

  # For keeb
  hardware.ckb-next = {
    enable = true;
    package = pkgs.ckb-next.overrideAttrs (old: {
      cmakeFlags = (old.cmakeFlags or [ ]) ++ [ "-DUSE_DBUS_MENU=0" ];
    });
  };

  # For rivalcfg
  services.udev.packages = [ pkgs.rivalcfg ];

  # For onlyoffice
  fonts.packages = with pkgs; [
    corefonts
  ];

  # --- Use appimage-run for AppImage ---
  programs.appimage = {
    enable = true;
    binfmt = true;
  };

  # --- Steam ---
  services.tuned.enable = true;
  programs.gamemode.enable = true;
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
  };

  # --- ZSWAP Device ---
  fileSystems."/swap" = {
    device = "/dev/disk/by-uuid/0ae15a10-33cf-4d69-a3df-b8b635dd902e";
    fsType = "btrfs";
    options = [ "subvol=@swap" "noatime" ];
  };

  swapDevices = [ {
    device = "/swap/swapfile";
  } ];

  # --- Graphics ---
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    # Needed for some ROCm to see the GPU
    extraPackages = with pkgs; [
      rocmPackages.clr.icd
    ];
  };

  # Enable nix-ld (needed for running pip wheels)
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

  # --- Standard stuff ---
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  system.stateVersion = "25.05";
}
