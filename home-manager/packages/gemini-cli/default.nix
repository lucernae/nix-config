{ stdenv, fetchurl, makeWrapper, nodejs, cacert, lib, ... }:
let
  gemini-cli = stdenv.mkDerivation rec {
    pname = "gemini-cli";
    version = "0.1.3";

    src = fetchurl {
      url = "https://registry.npmjs.org/@google/gemini-cli/-/gemini-cli-0.1.3.tgz";
      sha256 = "sha256-wS21HhdunxsPXDKd91ltEJnpGTxEwu9vPFs5wPVooYQ=";
    };

    nativeBuildInputs = [ makeWrapper ];

    env = {
      NPM_CONFIG_PROGRESS = "false"; # Disable progress bar
      NPM_CONFIG_FUND = "false"; # Disable funding message
      NPM_CONFIG_AUDIT = "false"; # Disable audit
      NPM_CONFIG_UPDATE_NOTIFIER = "false"; # Disable update notifications
      CI = "true"; # Run in CI mode
      SSL_CERT_FILE = "${cacert}/etc/ssl/certs/ca-bundle.crt"; # Add SSL cert path
      SYSTEM_CERTIFICATE_PATH = "${cacert}/etc/ssl/certs/ca-bundle.crt"; # Additional cert path
    };


    buildPhase = ''
      export HOME=$TMPDIR  # Set home directory for npm cache
      export npm_config_cafile=${cacert}/etc/ssl/certs/ca-bundle.crt
      export PATH="${nodejs}/bin:$PATH"
      echo "install node_modules"
      ${nodejs}/bin/npm install --no-progress --no-audit --loglevel info
    '';

    installPhase = ''
      mkdir -p $out/bin
      cp -r . $out/
      makeWrapper ${nodejs}/bin/node $out/bin/gemini --add-flags $out/dist/index.js
    '';

    meta = with lib; {
      description = "Google Gemini CLI";
      homepage = "https://github.com/google-gemini/gemini-cli";
      license = licenses.asl20;
      maintainers = with maintainers; [ ];
      platforms = platforms.all;
    };
  };
in
gemini-cli
