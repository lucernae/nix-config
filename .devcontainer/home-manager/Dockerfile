FROM ghcr.io/lucernae/devcontainer-nix:flake---latest

# See full lists of options here
# https://github.com/lucernae/devcontainer-nix/tree/main/templates/src/nix

ENV USE_DIRENV="true"
ENV USE_FLAKE="true"
ENV INSTALL_ROOT_PACKAGES="nixpkgs#ps nixpkgs#getconf"
ENV PREBUILD_DEFAULT_PACKAGE=""
ENV PREBUILD_NIX_SHELL=""
ENV PREBUILD_FLAKE=""
ENV PREBUILD_FLAKE_RUN=""
ENV PREBUILD_FLAKE_DEVELOP="true"
ENV ADDITIONAL_NIX_CHANNEL=""
ENV ADDITIONAL_NIX_FLAKE_REGISTRY=""
ENV PREBUILD_HOME_MANAGER=""
ENV PREBUILD_HOME_MANAGER_FLAKE="./home-manager#vscode"

COPY library-scripts /library-scripts

RUN bash /library-scripts/build/all.sh
