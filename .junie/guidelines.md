# Development Guidelines for Nix Configuration

This document provides guidelines and instructions for developing and maintaining this Nix configuration repository.

## Build/Configuration Instructions

### Prerequisites

- Nix package manager installed (multi-user installation recommended)
- Nix Flakes enabled

### Installing Nix

For a fresh setup, install Nix as a multi-user installation:

```bash
sh <(curl -L https://nixos.org/nix/install) --daemon
```

For isolated environments (WSL2, containers, etc.), use the standalone installation:

```bash
sh <(curl -L https://nixos.org/nix/install) --no-daemon
```

### Enabling Nix Flakes

Enable Nix Flakes by adding the following to your Nix configuration:

```bash
mkdir -p ~/.config/nix
echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf
```

### Building and Applying Configurations

#### For NixOS Systems

Build and switch to a NixOS configuration:

```bash
# From the repository root
nixos-rebuild switch --flake .#vmware
```

Replace `vmware` with the name of your NixOS configuration.

#### For Darwin (macOS) Systems

Build and switch to a Darwin configuration:

```bash
# From the repository root
darwin-rebuild switch --flake .#recalune
```

Replace `recalune` with the name of your Darwin configuration.

#### For Home Manager Only

Apply a standalone Home Manager configuration:

```bash
# From the home-manager directory
home-manager switch --flake .#recalune
```

Replace `recalune` with the name of your Home Manager configuration.

## Testing Information

### Testing Framework

This repository uses a simple testing approach based on Nix derivations. Tests are located in the `.junie/tests` directory.

### Running Tests

To run all tests:

```bash
# From the repository root
./.junie/tests/run-test.sh
```

### Adding New Tests

1. Create a new Nix file in the `.junie/tests` directory
2. Define a test derivation that evaluates the configuration or functionality you want to test
3. Update the `run-test.sh` script to include your new test

### Example Test

Here's an example of a simple test that verifies a Nix expression can be evaluated:

```nix
{ pkgs ? import <nixpkgs> {} }:

let
  testExpr = {
    name = "test-config";
    description = "A simple test configuration";
    # ... other attributes
  };
in
{
  # Return the test expression
  inherit testExpr;

  # A derivation that succeeds if the test expression can be evaluated
  test = pkgs.runCommand "test-nix-config" {} ''
    echo "Test expression evaluates successfully!"
    echo "Name: ${testExpr.name}"
    # ... other assertions
    touch $out
  '';
}
```

## Additional Development Information

### Code Style

This repository uses the following code style guidelines:

- Nix files are formatted using `nixpkgs-fmt`
- Pre-commit hooks are used to enforce code style
- Files should end with a newline
- No trailing whitespace

### Pre-commit Hooks

This repository uses pre-commit hooks to enforce code style. To set up pre-commit:

```bash
# Install pre-commit
nix-shell -p pre-commit

# Install the hooks
pre-commit install
```

To manually run the pre-commit hooks on all files:

```bash
pre-commit run --all-files
```

### Development Shell

A development shell is provided for convenience. To enter the development shell:

```bash
# From the repository root
nix develop
```

This provides access to useful commands like:

- `pre-commit`: Run pre-commit hooks
- `pcr`: Run pre-commit hooks on all files
- `flake-update`: Update flake inputs

### Project Structure

- `flake.nix`: Main entry point for the Nix flake
- `home-manager/`: Home Manager configurations
- `systems/`: System configurations (NixOS, Darwin)
- `hardware/`: Hardware-specific configurations
- `modules/`: Reusable Nix modules
- `services/`: Service configurations
- `.junie/tests/`: Test files

### Updating Dependencies

To update all flake inputs:

```bash
nix flake update
```

To update a specific input:

```bash
nix flake lock --update-input nixpkgs
```

Or use the provided `flake-update` command in the development shell:

```bash
flake-update nixpkgs
```
