{ config, pkgs, lib, ... }:

{
  services.flatpak = {
    enable = true;
    uninstallUnmanaged = true;
    
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
      {appId = "com.stremio.Stremio"; origin = "flathub-beta";}
      "us.zoom.Zoom"
      "it.mijorus.gearlever"
      "com.spotify.Client"
    ];
  };

  # Weekly Cleanup Service
  systemd.services.flatpak-cleanup = {
    description = "Cleanup unused Flatpak runtimes";
    script = "${pkgs.flatpak}/bin/flatpak uninstall --unused --noninteractive";
    serviceConfig.Type = "oneshot";
  };

  systemd.timers.flatpak-cleanup = {
    description = "Weekly Flatpak garbage collection";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "weekly";
      Persistent = true;
    };
  };
}
