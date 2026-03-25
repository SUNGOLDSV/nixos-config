{ config, pkgs, inputs, ... }:

{
  home.username = "sungold";
  home.homeDirectory = "/home/sungold";

  home.packages = with pkgs; [
    btop
    fastfetch
    git
    mpv
    python314Packages.subliminal
    (inputs.zen-browser.packages."${pkgs.stdenv.hostPlatform.system}".default.override {
      nativeMessagingHosts = [ 
        pkgs.kdePackages.plasma-browser-integration 
      ];
    })
    kitty
    yt-dlp
    mangohud
    protonup-qt
    lutris
    aria2
    gemini-cli
    appimage-run
    onlyoffice-desktopeditors
    remmina
    nmap
    kdePackages.krdc
    kdePackages.kamoso
    vicinae
    zed-editor
    obs-studio
    opencomposite
    qwen-code
  ];

  # The state version is required and should stay stable
  home.stateVersion = "25.05"; 
  programs.home-manager.enable = true;
}
