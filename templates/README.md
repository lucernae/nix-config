# Flake Templates

This directory contains flake templates that can be used to initialize new projects.

## Available Templates

### DevShell

A simple development shell template using [numtide/devshell](https://github.com/numtide/devshell).

```bash
# Initialize a new project with the devshell template
nix flake init -t github:your-username/nix-config#devshell
```

See the [DevShell README](./devshell/README.md) for more details.

## Usage

You can use these templates to initialize new projects with:

```bash
# Using a template from a remote repository
nix flake init -t github:your-username/nix-config#<template-name>

# Using a template from a local clone of the repository
nix flake init -t /path/to/nix-config#<template-name>
```

## Adding New Templates

To add a new template:

1. Create a new directory in the `templates` directory
2. Add a `flake.nix` file to the new directory
3. Add a `README.md` file with usage instructions
4. Update the `templates/flake.nix` file to include the new template
5. Update the main `flake.nix` file to include the new template in the outputs
