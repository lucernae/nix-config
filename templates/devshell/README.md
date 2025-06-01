# DevShell Template

This is a simple development shell template using [numtide/devshell](https://github.com/numtide/devshell).

## Usage

You can create a new project using this template with:

```bash
nix flake init -t github:your-username/nix-config#devshell
```

Or if you've cloned the repository:

```bash
nix flake init -t /path/to/nix-config#devshell
```

## Features

- Provides a development shell with common tools (git, curl, jq)
- Includes a sample command and environment variable
- Easy to customize with your own packages, commands, and environment variables

## Customization

Edit the `flake.nix` file to:

1. Change the project name (line 21)
2. Add or remove packages (lines 22-27)
3. Add or modify commands (lines 28-35)
4. Set environment variables (lines 36-42)

## Entering the Shell

Once you've initialized your project with this template, you can enter the development shell with:

```bash
nix develop
```

This will give you access to all the tools and commands defined in the flake.