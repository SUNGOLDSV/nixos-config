{ config, pkgs, inputs, ... }:

{
  home.username = "sungold";
  home.homeDirectory = "/home/sungold";

  home.packages = with pkgs; [
    btop
    fastfetch
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
    protonplus
    lutris
    aria2
    antigravity-cli
    appimage-run
    onlyoffice-desktopeditors
    remmina
    nmap
    kdePackages.krdc
    kdePackages.kamoso
    kdePackages.filelight
    vicinae
    zed-editor
    obs-studio
    opencomposite
    furmark
    obsidian
    android-tools
    pdfarranger
    (prismlauncher.override {
      jdks = [zulu21];
    })
#    (inputs.opencode.packages.${pkgs.stdenv.hostPlatform.system}.opencode.overrideAttrs (old: {
#        preBuild = (old.preBuild or "") + ''
#          substituteInPlace packages/opencode/src/cli/cmd/generate.ts \
#            --replace-fail 'const prettier = await import("prettier")' 'const prettier: any = { format: async (s: string) => s }' \
#            --replace-fail 'const babel = await import("prettier/plugins/babel")' 'const babel = {}' \
#            --replace-fail 'const estree = await import("prettier/plugins/estree")' 'const estree = {}'
#        '';
#    }))
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
            ${pkgs.python3Packages.subliminal}/bin/subliminal download -l en -d /tmp/mpv-subs "$1" > /dev/null 2>&1

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

  services.easyeffects = {
    enable = true;
  };

  xdg.configFile."pipewire/pipewire.conf.d/99-virtual-surround.conf".text = ''
    # Convolver sink
    #
    # Copy this file into a conf.d/ directory such as
    # ~/.config/pipewire/filter-chain.conf.d/
    #
    # Adjust the paths to the convolver files to match your system
    #
    context.modules = [
      { name = libpipewire-module-filter-chain
          flags = [ nofail ]
          args = {
              node.description = "Virtual Surround Sink"
              media.name       = "Virtual Surround Sink"
              filter.graph = {
                  nodes = [
                      # duplicate inputs
                      { type = builtin label = copy name = copyFL  }
                      { type = builtin label = copy name = copyFR  }
                      { type = builtin label = copy name = copyFC  }
                      { type = builtin label = copy name = copyRL  }
                      { type = builtin label = copy name = copyRR  }
                      { type = builtin label = copy name = copySL  }
                      { type = builtin label = copy name = copySR  }
                      { type = builtin label = copy name = copyLFE }

                      # apply hrir - HeSuVi 14-channel WAV (not the *-.wav variants) (note: */44/* in HeSuVi are the same, but resampled to 44100)
                      { type = builtin label = convolver name = convFL_L config = { filename = "/home/sungold/.config/pipewire/hrir/atmos.wav" channel =  0 } }
                      { type = builtin label = convolver name = convFL_R config = { filename = "/home/sungold/.config/pipewire/hrir/atmos.wav" channel =  1 } }
                      { type = builtin label = convolver name = convSL_L config = { filename = "/home/sungold/.config/pipewire/hrir/atmos.wav" channel =  2 } }
                      { type = builtin label = convolver name = convSL_R config = { filename = "/home/sungold/.config/pipewire/hrir/atmos.wav" channel =  3 } }
                      { type = builtin label = convolver name = convRL_L config = { filename = "/home/sungold/.config/pipewire/hrir/atmos.wav" channel =  4 } }
                      { type = builtin label = convolver name = convRL_R config = { filename = "/home/sungold/.config/pipewire/hrir/atmos.wav" channel =  5 } }
                      { type = builtin label = convolver name = convFC_L config = { filename = "/home/sungold/.config/pipewire/hrir/atmos.wav" channel =  6 } }
                      { type = builtin label = convolver name = convFR_R config = { filename = "/home/sungold/.config/pipewire/hrir/atmos.wav" channel =  7 } }
                      { type = builtin label = convolver name = convFR_L config = { filename = "/home/sungold/.config/pipewire/hrir/atmos.wav" channel =  8 } }
                      { type = builtin label = convolver name = convSR_R config = { filename = "/home/sungold/.config/pipewire/hrir/atmos.wav" channel =  9 } }
                      { type = builtin label = convolver name = convSR_L config = { filename = "/home/sungold/.config/pipewire/hrir/atmos.wav" channel = 10 } }
                      { type = builtin label = convolver name = convRR_R config = { filename = "/home/sungold/.config/pipewire/hrir/atmos.wav" channel = 11 } }
                      { type = builtin label = convolver name = convRR_L config = { filename = "/home/sungold/.config/pipewire/hrir/atmos.wav" channel = 12 } }
                      { type = builtin label = convolver name = convFC_R config = { filename = "/home/sungold/.config/pipewire/hrir/atmos.wav" channel = 13 } }

                      # treat LFE as FC
                      { type = builtin label = convolver name = convLFE_L config = { filename = "/home/sungold/.config/pipewire/hrir/atmos.wav" channel =  6 } }
                      { type = builtin label = convolver name = convLFE_R config = { filename = "/home/sungold/.config/pipewire/hrir/atmos.wav" channel = 13 } }

                      # stereo output
                      { type = builtin label = mixer name = mixL }
                      { type = builtin label = mixer name = mixR }
                  ]
                  links = [
                      # input
                      { output = "copyFL:Out"  input="convFL_L:In"  }
                      { output = "copyFL:Out"  input="convFL_R:In"  }
                      { output = "copySL:Out"  input="convSL_L:In"  }
                      { output = "copySL:Out"  input="convSL_R:In"  }
                      { output = "copyRL:Out"  input="convRL_L:In"  }
                      { output = "copyRL:Out"  input="convRL_R:In"  }
                      { output = "copyFC:Out"  input="convFC_L:In"  }
                      { output = "copyFR:Out"  input="convFR_R:In"  }
                      { output = "copyFR:Out"  input="convFR_L:In"  }
                      { output = "copySR:Out"  input="convSR_R:In"  }
                      { output = "copySR:Out"  input="convSR_L:In"  }
                      { output = "copyRR:Out"  input="convRR_R:In"  }
                      { output = "copyRR:Out"  input="convRR_L:In"  }
                      { output = "copyFC:Out"  input="convFC_R:In"  }
                      { output = "copyLFE:Out" input="convLFE_L:In" }
                      { output = "copyLFE:Out" input="convLFE_R:In" }

                      # output
                      { output = "convFL_L:Out"  input="mixL:In 1" }
                      { output = "convFL_R:Out"  input="mixR:In 1" }
                      { output = "convSL_L:Out"  input="mixL:In 2" }
                      { output = "convSL_R:Out"  input="mixR:In 2" }
                      { output = "convRL_L:Out"  input="mixL:In 3" }
                      { output = "convRL_R:Out"  input="mixR:In 3" }
                      { output = "convFC_L:Out"  input="mixL:In 4" }
                      { output = "convFC_R:Out"  input="mixR:In 4" }
                      { output = "convFR_R:Out"  input="mixR:In 5" }
                      { output = "convFR_L:Out"  input="mixL:In 5" }
                      { output = "convSR_R:Out"  input="mixR:In 6" }
                      { output = "convSR_L:Out"  input="mixL:In 6" }
                      { output = "convRR_R:Out"  input="mixR:In 7" }
                      { output = "convRR_L:Out"  input="mixL:In 7" }
                      { output = "convLFE_R:Out" input="mixR:In 8" }
                      { output = "convLFE_L:Out" input="mixL:In 8" }
                  ]
                  inputs  = [ "copyFL:In" "copyFR:In" "copyFC:In" "copyLFE:In" "copyRL:In" "copyRR:In", "copySL:In", "copySR:In" ]
                  outputs = [ "mixL:Out" "mixR:Out" ]
              }
              capture.props = {
                  node.name      = "effect_input.virtual-surround-7.1-hesuvi"
                  media.class    = Audio/Sink
                  audio.channels = 8
                  audio.position = [ FL FR FC LFE RL RR SL SR ]
              }
              playback.props = {
                  node.name      = "effect_output.virtual-surround-7.1-hesuvi"
                  node.passive   = true
                  audio.channels = 2
                  audio.position = [ FL FR ]
              }
          }
      }
  ]

  '';

  # The state version is required and should stay stable
  home.stateVersion = "25.05";
  programs.home-manager.enable = true;
}
