{ 
  pkgs,
  s1managementToken,
  email,
  serialNumber
}:
let
  sentinelOnePackage = "SentinelAgent-Linux-22-3-3-11-x86-64-release-22-3-3_linux_v22_3_3_11.deb";
in
pkgs.stdenv.mkDerivation rec {
  pname   = "sentinelone";
  version = "22_3_3_11";

  # Calliope\ TODO: Do we need to vendor this???
  # Wheres the .deb repo?
  srcs = [
    (pkgs.fetchurl {
      url = "https://imugit.imubit.com/morgan.helton/sentinelone/-/raw/main/${sentinelOnePackage}";
      hash = "sha256-Ti9y5VLLMa7CQMJJpJuAiaNwZyf2VSaeD1o/cCPPfUk=";
    })
    ./bootstrap-sentinelone
  ];

  unpackPhase = ''
    for s in $srcs; do
      n=$(stripHash $s)
      cp $s $n
    done
    dpkg-deb -x ${sentinelOnePackage} .
  '';

  # Calliope\ Tell sentinelone that its actually installed itself
  # by cleverly writing an install_config
  buildPhase = ''
    cat << EOF > install_config
S1_AGENT_MANAGEMENT_TOKEN=${s1managementToken}
S1_AGENT_DEVICE_TYPE=desktop
S1_AGENT_AUTO_START=true
S1_AGENT_CUSTOMER_ID=${email}-${serialNumber}
EOF

    cat << EOF > installation_params.json
  {
    "PACKAGE_TYPE": "deb",
    "SERVICE_TYPE": "systemd"
  }
EOF
  siteKey=$(echo ${s1managementToken} | base64 -d | jq .site_key)
  mgmtUrl=$(echo ${s1managementToken} | base64 -d | jq .url)
  cat << EOF > basic.conf
{
    "mgmt_device-type": 1,
    "mgmt_site-key": $siteKey,
    "mgmt_url": $mgmtUrl
}
EOF
  '';

  nativeBuildInputs = [
    pkgs.dpkg
    pkgs.autoPatchelfHook
    pkgs.zlib
    pkgs.libelf
    pkgs.dmidecode
    pkgs.jq
    pkgs.gcc-unwrapped
  ];

  installPhase = ''
    mkdir -p $out/opt/
    mkdir -p $out/cfg/
    mkdir -p $out/bin/

    chmod +x bootstrap-sentinelone
    cp bootstrap-sentinelone $out/bin/

    cp -r opt/* $out/opt
    
    ln -s $out/opt/sentinelone/bin/sentinelctl $out/bin/sentinelctl
    ln -s $out/opt/sentinelone/bin/sentinelone-agent $out/bin/sentinelone-agent
    ln -s $out/opt/sentinelone/bin/sentinelone-watchdog $out/bin/sentinelone-watchdog
    ln -s $out/opt/sentinelone/lib $out/lib

    mv install_config $out/cfg/
    mv installation_params.json $out/cfg/
    mv basic.conf $out/cfg/
  '';
}
