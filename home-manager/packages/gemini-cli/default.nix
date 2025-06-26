{ lib, buildNpmPackage, importNpmLock, cacert, fetchFromGitHub, nodejs, makeWrapper }:

buildNpmPackage rec {
  pname = "gemini-cli";
  version = "0.1.5";

  src = fetchFromGitHub {
    owner = "google-gemini";
    repo = "gemini-cli";
    rev = "01ff27709d7b62491bc2438fb8939da034c1c003";
    sha256 = "sha256-JgiK+8CtMrH5i4ohe+ipyYKogQCmUv5HTZgoKRNdnak=";
  };

  npmDepsHash = "sha256-yoUAOo8OwUWG0gyI5AdwfRFzSZvSCd3HYzzpJRvdbiM=";

  # Ensure makeWrapper is available during build
  nativeBuildInputs = [ makeWrapper ];

  npmFlags = [
    "--no-audit"
    "--no-fund"
    "--loglevel=verbose"
  ];

  # Environment variables to help with DNS resolution
  env = {
    CI = "true"; # Run in CI mode
    SSL_CERT_FILE = "${cacert}/etc/ssl/certs/ca-bundle.crt"; # Add SSL cert path
    SYSTEM_CERTIFICATE_PATH = "${cacert}/etc/ssl/certs/ca-bundle.crt"; # Additional cert path
  };

  # Allow binary substitutes if available
  allowSubstitutes = true;

  # Create a wrapper script to run the CLI
  # When building from GitHub source, the path structure might be different
  postInstall = ''
    mkdir -p $out/bin
    # remove unused symlinks to avoid noBrokenSymlinks

    pushd $out/lib/node_modules/@google/gemini-cli/node_modules
    rm ./.bin/gemini
    rm -f @google/gemini-cli
    rm -f @google/gemini-cli-core

    makeWrapper ${nodejs}/bin/node $out/bin/gemini \
        --add-flags $out/lib/node_modules/@google/gemini-cli/bundle/gemini.js \
        --prefix PATH : ${lib.makeBinPath [ nodejs ]}
  '';

  meta = with lib; {
    description = "Google Gemini CLI";
    homepage = "https://github.com/google-gemini/gemini-cli";
    license = licenses.asl20;
    maintainers = with maintainers; [ ];
    platforms = platforms.all;
  };
}
