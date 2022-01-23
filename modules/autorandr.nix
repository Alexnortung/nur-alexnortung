{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.services.autorandr;
  hookType = types.lines;
  globalHooksModule = types.submodule {
    options = {
      postswitch = mkOption {
        type = types.attrsOf hookType;
        description = "Postswitch hook executed after mode switch.";
        default = { };
      };

      preswitch = mkOption {
        type = types.attrsOf hookType;
        description = "Preswitch hook executed before mode switch.";
        default = { };
      };

      predetect = mkOption {
        type = types.attrsOf hookType;
        description = ''
          Predetect hook executed before autorandr attempts to run xrandr.
        '';
        default = { };
      };
    };
  };
  hookToFile = folder: name: hook:
    nameValuePair "xdg/autorandr/${folder}/${name}" {
      source = "${pkgs.writeShellScriptBin "hook" hook}/bin/hook";
    };

in {

  options = {

    services.autorandr = {
      enable = mkEnableOption "handling of hotplug and sleep events by autorandr";

      defaultTarget = mkOption {
        default = "default";
        type = types.str;
        description = ''
          Fallback if no monitor layout can be detected. See the docs
          (https://github.com/phillipberndt/autorandr/blob/v1.0/README.md#how-to-use)
          for further reference.
        '';
      };

      hooks = mkOption {
        type = globalHooksModule;
        description = "Global hook scripts";
        default = { };
        example = ''
          {
            postswitch = {
              "notify-i3" = "''${pkgs.i3}/bin/i3-msg restart";
              "change-background" = readFile ./change-background.sh;
              "change-dpi" = '''
                case "$AUTORANDR_CURRENT_PROFILE" in
                  default)
                    DPI=120
                    ;;
                  home)
                    DPI=192
                    ;;
                  work)
                    DPI=144
                    ;;
                  *)
                    echo "Unknown profle: $AUTORANDR_CURRENT_PROFILE"
                    exit 1
                esac
                echo "Xft.dpi: $DPI" | ''${pkgs.xorg.xrdb}/bin/xrdb -merge
              '''
            };
          }
        '';
      };

    };

  };

  config = mkIf cfg.enable {

    services.udev.packages = [ pkgs.autorandr ];

    environment = {
      systemPackages = [ pkgs.autorandr ];
      etc = mkMerge ([
        (mapAttrs' (hookToFile "postswitch.d") cfg.hooks.postswitch)
        (mapAttrs' (hookToFile "preswitch.d") cfg.hooks.preswitch)
        (mapAttrs' (hookToFile "predetect.d") cfg.hooks.predetect)
      ]);
    };

    systemd.services.autorandr = {
      wantedBy = [ "sleep.target" ];
      description = "Autorandr execution hook";
      after = [ "sleep.target" ];

      startLimitIntervalSec = 5;
      startLimitBurst = 1;
      serviceConfig = {
        ExecStart = "${pkgs.autorandr}/bin/autorandr --batch --change --default ${cfg.defaultTarget}";
        Type = "oneshot";
        RemainAfterExit = false;
      };
    };

  };
}
