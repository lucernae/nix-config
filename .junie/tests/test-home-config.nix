{ pkgs ? import <nixpkgs> { } }:

let
  # Create a simple test that checks if a Nix expression can be evaluated
  testExpr = {
    # A simple attribute set with some values
    name = "test-config";
    description = "A simple test configuration";

    # A list of packages that might be used in the configuration
    packages = [
      "git"
      "zsh"
      "vim"
    ];

    # A nested attribute set with some configuration options
    settings = {
      enableFeatureA = true;
      enableFeatureB = false;
      maxConnections = 10;
    };
  };
in
{
  # Return the test expression
  inherit testExpr;

  # A derivation that succeeds if the test expression can be evaluated
  test = pkgs.runCommand "test-nix-config" { } ''
    echo "Test expression evaluates successfully!"
    echo "Name: ${testExpr.name}"
    echo "Description: ${testExpr.description}"
    echo "Number of packages: ${toString (builtins.length testExpr.packages)}"
    echo "Feature A enabled: ${toString testExpr.settings.enableFeatureA}"
    echo "Feature B enabled: ${toString testExpr.settings.enableFeatureB}"
    echo "Max connections: ${toString testExpr.settings.maxConnections}"
    touch $out
  '';
}
