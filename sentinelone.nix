{ stdenv
, fetchurl
, dpkg
, autoPatchelfHook
, zlib
, libelf
, dmidecode
, jq
, gcc-unwrapped
}:
let
  sentinelOnePackage = "SentinelAgent-Linux-22-3-3-11-x86-64-release-22-3-3_linux_v22_3_3_11.deb";
in
stdenv.mkDerivation rec {
  pname   = "sentinelone";
  version = "22.3.3.11";

  src = fetchurl {
      url = "https://imugit.imubit.com/morgan.helton/sentinelone/-/raw/main/${sentinelOnePackage}";
      hash = "sha256-Ti9y5VLLMa7CQMJJpJuAiaNwZyf2VSaeD1o/cCPPfUk=";
  };

  unpackPhase = ''
    runHook preUnpack

    dpkg-deb -x $src .

    runHook postUnpack
  '';

  nativeBuildInputs = [
    dpkg
    autoPatchelfHook
    zlib
    libelf
    dmidecode
    jq
    gcc-unwrapped
  ];

  installPhase = ''
    mkdir -p $out/opt/
    mkdir -p $out/cfg/
    mkdir -p $out/bin/

    cp -r opt/* $out/opt
    
    ln -s $out/opt/sentinelone/bin/sentinelctl $out/bin/sentinelctl
    ln -s $out/opt/sentinelone/bin/sentinelone-agent $out/bin/sentinelone-agent
    ln -s $out/opt/sentinelone/bin/sentinelone-watchdog $out/bin/sentinelone-watchdog
    ln -s $out/opt/sentinelone/lib $out/lib
  '';
}
