{ lib, pkgs, config, ... }:
with lib;
  let
    cfg = config.services.sentinelone;
    initScript = pkgs.writeShellScriptBin "sentinelone-init.sh" ''
      #!/bin/bash

      # initialize the data directory
      if [ -z "$(ls -A ${cfg.dataDir} 2>/dev/null)" ]; then
        cp -r ${pkgs.sentinelone}/opt/sentinelone/* ${cfg.dataDir}

        cat << EOF > ${cfg.dataDir}/configuration/install_config
      S1_AGENT_MANAGEMENT_TOKEN=${cfg.sentinelOneManagementToken}
      S1_AGENT_DEVICE_TYPE=desktop
      S1_AGENT_AUTO_START=true
      S1_AGENT_CUSTOMER_ID=${cfg.email}-${cfg.serialNumber}
      EOF

        cat << EOF > ${cfg.dataDir}/configuration/installation_params.json
      {
        "PACKAGE_TYPE": "deb",
        "SERVICE_TYPE": "systemd"
      }
      EOF
          siteKey=$(echo ${cfg.sentinelOneManagementToken} | base64 -d | ${getExe pkgs.jq} .site_key)
          mgmtUrl=$(echo ${cfg.sentinelOneManagementToken} | base64 -d | ${getExe pkgs.jq} .url)
        cat << EOF > ${cfg.dataDir}/configuration/basic.conf
      {
          "mgmt_device-type": 1,
          "mgmt_site-key": $siteKey,
          "mgmt_url": $mgmtUrl
      }
      EOF

        chown -R sentinelone:sentinelone ${cfg.dataDir}
      fi
    '';
  in {
    options = {
      services = {
        sentinelone = {
          enable = mkEnableOption "SentinelOne Service";
          package = mkPackageOption pkgs "sentinelone";
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
          dataDir = mkOption {
            type = types.path;
            default = "/var/lib/sentinelone";
          };
        };
      };
    };

    config = mkIf cfg.enable {

      users.users.sentinelone = {
        isSystemUser = true;
        createHome   = true;
        shell        = "${pkgs.shadow}/bin/nologin";
        group        = "sentinelone";
      };
      users.groups.sentinelone = { };

      systemd.services.sentinelone-init = {
        wantedBy = [ "sentinelone.service" ];
        before = [ "sentinelone.service" ];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${getExe initScript}";
        };
      };

      systemd.services.sentinelone = {
        enable = true;
        description = "SentinelOne";
        path = [
          pkgs.coreutils-full
          pkgs.gawk
          pkgs.zlib
          pkgs.libelf
          pkgs.bash
        ];
        unitConfig = {
          Description = "SentinelOne";
          After = [
            "uptrack-prefetch.service"
            "uptrack.service"
          ];
        };
        serviceConfig = {
          Type="forking";
          ExecStart="${pkgs.sentinelone}/bin/sentinelctl control run";
          SyslogIdentifier="/var/lib/sentinelone/log";
          WatchdogSec="5s";
          Restart="always";
          StartLimitInterval="90";
          StartLimitBurst="4";
          RestartSec="4";
          MemoryMax="9223372036854771712";
          ExecStop="${pkgs.sentinelone}/bin/sentinelctl control shutdown";
          NotifyAccess="all";
          KillMode="process";
          PIDFile="/var/lib/sentinelone/configuration/agent.pid";
          TasksMax="infinity";
          BindPaths="/var/lib/sentinelone:/opt/sentinelone";
        };
        wantedBy = [ "multi-user.target" ];
      };
    };
  }

