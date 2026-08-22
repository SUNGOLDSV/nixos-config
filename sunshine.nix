{ config, pkgs, ... }:

let
  sunshine-start-vmon = pkgs.writeShellScriptBin "sunshine-start-vmon" ''
    exec > /tmp/sunshine-start-vmon.log 2>&1
    echo "=== Starting Virtual Monitor ==="
    date
    
    # Read client resolution variables, defaulting to 1080p if empty
    WIDTH="''${SUNSHINE_CLIENT_WIDTH:-1920}"
    HEIGHT="''${SUNSHINE_CLIENT_HEIGHT:-1080}"
    echo "Target Resolution: ''${WIDTH}x''${HEIGHT}"

    # Ensure any previous instance of the transient service is stopped
    echo "Stopping existing virtual monitor service if any..."
    ${pkgs.systemd}/bin/systemctl --user stop sunshine-virtual-monitor >/dev/null 2>&1 || true

    # Launch krfb-virtualmonitor as a transient user service
    echo "Running krfb-virtualmonitor via systemd-run..."
    ${pkgs.systemd}/bin/systemd-run --user --unit=sunshine-virtual-monitor \
      ${pkgs.kdePackages.krfb}/bin/krfb-virtualmonitor \
      --resolution "''${WIDTH}x''${HEIGHT}" \
      --name "sunshine" \
      --password "dummy" \
      --port 5900

    # Wait for the virtual monitor to register with KScreen (up to 5 seconds)
    echo "Waiting for Virtual-sunshine to appear..."
    for i in {1..10}; do
      if ${pkgs.kdePackages.libkscreen}/bin/kscreen-doctor -o | grep -q "Virtual-sunshine"; then
        echo "Virtual-sunshine monitor detected."
        break
      fi
      sleep 0.5
    done

    # To prevent Wayland compositor suspension, we must NOT disable eDP-1.
    # We position Virtual-sunshine at 0,0, make it the primary screen, and position
    # eDP-1 side-by-side at (WIDTH, 0) so both remain active.
    echo "Configuring display layout: Virtual-sunshine as primary at 0,0; eDP-1 at ''${WIDTH},0"
    ${pkgs.kdePackages.libkscreen}/bin/kscreen-doctor \
      output.Virtual-sunshine.enable \
      output.Virtual-sunshine.primary \
      output.Virtual-sunshine.position.0,0 \
      output.eDP-1.position.''${WIDTH},0
    
    echo "=== Start Script Completed ==="
  '';

  sunshine-stop-vmon = pkgs.writeShellScriptBin "sunshine-stop-vmon" ''
    exec > /tmp/sunshine-stop-vmon.log 2>&1
    echo "=== Stopping Virtual Monitor ==="
    date
    
    # Ensure laptop screen is active, positioned at 0,0, and restored as the primary display
    echo "Restoring internal screen eDP-1 as primary..."
    ${pkgs.kdePackages.libkscreen}/bin/kscreen-doctor \
      output.eDP-1.enable \
      output.eDP-1.primary \
      output.eDP-1.position.0,0

    sleep 1

    # Stop the virtual monitor service
    echo "Stopping sunshine-virtual-monitor service..."
    ${pkgs.systemd}/bin/systemctl --user stop sunshine-virtual-monitor
    
    echo "=== Stop Script Completed ==="
  '';
in
{
  environment.systemPackages = [
    pkgs.kdePackages.krfb
    sunshine-start-vmon
    sunshine-stop-vmon
  ];

  services.sunshine = {
    enable = true;
    autoStart = false;
    openFirewall = true;
    capSysAdmin = true;
  };

  # Declaratively configure home-manager user settings from inside this module!
  home-manager.users.sungold = {
    xdg.configFile."sunshine/sunshine.conf".text = ''
      adapter_name = /dev/dri/by-path/pci-0000:08:00.0-render
      capture = kwin
      encoder = vaapi
      output_name = Virtual-sunshine
      stream_audio = disabled
    '';

    xdg.configFile."sunshine/apps.json".text = builtins.toJSON {
      env = {};
      apps = [
        {
          name = "Desktop";
          prep-cmd = [
            {
              do = "${sunshine-start-vmon}/bin/sunshine-start-vmon";
              undo = "${sunshine-stop-vmon}/bin/sunshine-stop-vmon";
              elevated = false;
            }
          ];
        }
        {
          name = "Steam Big Picture";
          detached = [
            "${pkgs.util-linux}/bin/setsid /run/current-system/sw/bin/steam steam://open/bigpicture"
          ];
          prep-cmd = [
            {
              do = "${sunshine-start-vmon}/bin/sunshine-start-vmon";
              undo = "${pkgs.util-linux}/bin/setsid /run/current-system/sw/bin/steam steam://close/bigpicture ; ${sunshine-stop-vmon}/bin/sunshine-stop-vmon";
              elevated = false;
            }
          ];
        }
      ];
    };
  };
}
