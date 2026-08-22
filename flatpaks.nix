{ config, pkgs, lib, ... }:

{
  services.flatpak = {
    enable = true;
    uninstallUnmanaged = true;
    uninstallUnused = true;
    
    # EXPLICITLY list both, first one is usually the default search target
    remotes = [
      {
        name = "flathub";
        location = "https://dl.flathub.org/repo/flathub.flatpakrepo";
      }
      {
        name = "flathub-beta";
        location = "https://flathub.org/beta-repo/flathub-beta.flatpakrepo";
      }
    ];

    packages = [
      "com.discordapp.Discord"
      {appId = "com.stremio.Stremio"; origin = "flathub";}
      "us.zoom.Zoom"
      "it.mijorus.gearlever"
      "it.mijorus.gearlever.Locale"
      "com.spotify.Client"
      "org.jeffvli.feishin"
      "com.mongodb.Compass"
    ];
  };
}
