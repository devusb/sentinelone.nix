{ lib, pkgs, config, ... }:
with lib;
  let
    cfg = config.services.sentinel-one;
    
    sentinel-one = import ./sentinelone.nix {
      inherit pkgs;
      email = cfg.email;
      serialNumber = cfg.serialNumber;
      s1managementToken = cfg.sentinelOneManagementToken;
    };
  in {
    options = {
      services = {
        sentinel-one = {
          enable = mkEnableOption "SentinelOne Service";
          email = mkOption {
            type = types.str;
            example = "me@gmail.com";
          };
          serialNumber = mkOption {
            type = types.str;
            example = "FTXYZWW";
          };
          sentinelOneManagementToken = mkOption {
            type = types.str;
            example = "eyxxxxyyyyzzz";
          };
        };
      };
    };
    config = mkIf cfg.enable {
      # Calliope\ SentinelOne needs its own user, 
      # So lets add that here:
      users.users.sentinelone = {
        # Calliope\ SentinelOne is a system user. (useradd -r)
        isSystemUser = true;
        # Calliope\ SentinelOne gets its own home directory (useradd -d)
        createHome   = true;
        # Calliope\ SentinelOne isnt allowed a shell (useradd -s nologin)
        shell        = "${pkgs.shadow}/bin/nologin";
        group        = "sentinelone";
      };
      users.groups.sentinelone = { };

      environment.systemPackages = with pkgs; [
        sentinel-one
      ];

      systemd.services.sentinel-one = {
        enable = true;
        description = "Sentinel One";
        path = [
          pkgs.coreutils-full
          pkgs.gawk
          pkgs.zlib
          pkgs.libelf
          pkgs.bash
        ];
        unitConfig = {
          Description = "Sentinel One";
          After = [
            "uptrack-prefetch.service"
            "uptrack.service"
          ];
        };
        serviceConfig = {
          Type="forking";
          ExecStart="${sentinel-one}/bin/sentinelctl control run";
          SyslogIdentifier="/opt/sentinelone/log";
          WatchdogSec="5s";
          Restart="always";
          StartLimitInterval="90";
          StartLimitBurst="4";
          RestartSec="4";
          MemoryMax="9223372036854771712";
          ExecStop="${sentinel-one}//bin/sentinelctl control shutdown";
          NotifyAccess="all";
          KillMode="process";
          PIDFile="/opt/sentinelone/configuration/agent.pid";
          TasksMax="infinity";
        };
        wantedBy = [ "multi-user.target" ];
      };
    };
  }


