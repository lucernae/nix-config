# Home-Manager config

## Useful links

[Home-Manager manual](https://nix-community.github.io/home-manager/index.html#ch-nix-flakes
)

[Home-Manager repository](https://github.com/nix-community/home-manager)

## Flake based activation

Standard home-manager configuration contains a single configuration module called `home.nix`.

For a flake based setup, a `flake.nix` just calls `home.nix` module. So to actually write and maintain your modules, you edit the `home.nix`. You can also write several configuration in order to compose it together using home-manager `imports`. Refer to [Flake setup](https://nix-community.github.io/home-manager/index.html#ch-nix-flakes) for more info

A standalone flake is provided in this directory as an example.

If you include home-manager as part of NixOS or Nix-Darwin module, you can use the same `home.nix` as part of the configurations. This way, `darwin-rebuild` or `nixos-rebuild` will activate the home-manager too.
