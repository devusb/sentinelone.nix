# sentinelone-nix
## About
Package and module to use SentinelOne on NixOS. Based on the SentinelOne package from [GitLab](https://gitlab.com/gitlab-com/gl-infra/reliability).

## Usage
To use this module, add it to your flake inputs as
```
inputs.sentinelone.url = "github:devusb/sentinelone-nix";
```
Then, import and use the module in your NixOS configuration as
```
imports = [
    inputs.sentinelone.nixosModules.sentinelone
];
services.sentinelone = {
  enable = true;
  sentinelOneManagementTokenPath = /path/to/file/containing/token;
  email = "your@emailhere.com";
  serialNumber = "M4CH1N3";
  package = pkgs.sentinelone.overrideAttrs (old: {
    version = "sentinelone.package.version"; 
    src = pkgs.fetchurl {
        url = "https://url-to-sentinelone-package.deb";
        hash = "sentinelone-hash";
    };
  });
};
```
overriding `package` to point to a URL where a SentinelOne `deb` is available.

`sentinelOneManagementTokenPath` could be from a [sops-nix](https://github.com/Mic92/sops-nix) secret such as
```
sops = {
  secrets.s1_mgmt_token = {
    sopsFile = ../../secrets/sentinelone.yaml;
  };
};
services.sentinelone = {
  sentinelOneManagementTokenPath = config.sops.secrets.s1_mgmt_token.path;
};

```
