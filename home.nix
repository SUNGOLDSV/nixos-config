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
    (inputs.opencode.packages.${pkgs.stdenv.hostPlatform.system}.opencode.overrideAttrs (old: {
        preBuild = (old.preBuild or "") + ''
          substituteInPlace packages/opencode/src/cli/cmd/generate.ts \
            --replace-fail 'const prettier = await import("prettier")' 'const prettier: any = { format: async (s: string) => s }' \
            --replace-fail 'const babel = await import("prettier/plugins/babel")' 'const babel = {}' \
            --replace-fail 'const estree = await import("prettier/plugins/estree")' 'const estree = {}'
        '';
    }))
  ];

  xdg.configFile."mpv/scripts/rd-subs.lua".text = ''
    local mp = require 'mp'
    local utils = require 'mp.utils'

    function get_rd_subs()
        -- Grab the title
        local title = mp.get_property("media-title")
        if not title then return end

        mp.osd_message("Searching subs for: " .. title, 4)

        -- Use bash to run subliminal securely, piping the title as an argument
        -- This isolates the download to a temp folder and returns the new file path
        local bash_script = [[
            mkdir -p /tmp/mpv-subs
            rm -f /tmp/mpv-subs/*.srt

            # Search by plain text string instead of file hash
            subliminal download -l en -d /tmp/mpv-subs "$1" > /dev/null 2>&1

            # Print the path of the newly downloaded file back to MPV
            ls -t /tmp/mpv-subs/*.srt 2>/dev/null | head -n 1
        ]]

        local res = utils.subprocess({
            args = {"bash", "-c", bash_script, "--", title},
            cancellable = false,
        })

        if res.status == 0 and res.stdout and res.stdout ~= "" then
            -- Clean the output and load the subtitle track into the active stream
            local sub_path = res.stdout:gsub("\n", "")
            mp.commandv("sub-add", sub_path)
            mp.osd_message("Subtitle loaded successfully!", 3)
        else
            mp.osd_message("Subtitle not found in database.", 3)
        end
    end

    -- Bind the custom function to the 'b' key
    mp.add_key_binding("b", "get_rd_subs", get_rd_subs)
  '';

  # --- For openvr games opencomposite
  xdg.configFile."openvr/openvrpaths.vrpath".text = let
    steam = "${config.xdg.dataHome}/Steam";
  in builtins.toJSON {
    version = 1;
    jsonid = "vrpathreg";
    external_drivers = null;
    config = [ "${steam}/config" ];
    log = [ "${steam}/logs" ];
    # Points OpenVR games to OpenComposite instead of SteamVR
    runtime = [ "${pkgs.opencomposite}/lib/opencomposite" ];
  };

  # The state version is required and should stay stable
  home.stateVersion = "25.05"; 
  programs.home-manager.enable = true;
}
