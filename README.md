# nix-config
My personal collection of public nix related config and tutorial

## Bootstrapping

For fresh setup for your system, you either need Nix or NixOS

### Installing Nix

I recommends installing Nix as multi user installation in your system:

```bash
sh <(curl -L https://nixos.org/nix/install) --daemon
```

Nix can be installed as a standalone software. This might be needed in isolated environment without a daemon, such as 
WSL2, containers, or trying out nix without sudo access.

```bash
sh <(curl -L https://nixos.org/nix/install) --no-daemon
```

### Enabling Nix Flake imperatively

Since currently Nix Flake is an experimental feature, you need to enable it first imperatively. After that, you can use 
flake to enable Nix Flake declaratively as part of your system configuration

```bash
cat <<EOF >> ~/.config/nix/nix.conf
experimental-features = nix-command flakes
EOF
```

### Case: Bootstrapping NixOS

This would be a long article to write, so I will just consider it out of scope for now. However, theoritically it is 
possible to install NixOS from an existing working Linux distro. You need to map the correct partition and 
boot loader for it to be able to work and available from the GRUB menu after reboot.

### Case: Bootstrapping Nix-Darwin

In the case of Nix-Darwin, normally you already have a certain macOS running, but you want to maintain your 
system configuration via nix. In this case you use nix-darwin modules to manage some part of your macOS 
configuration so that you can install the same configuration quickly in various mac (very useful when you 
change your laptop or something).

First, build nix-darwin installer using nix flake. Assume that you have a flake recipe with minimal nix-darwin configuration.
Or you can use the one included in this repo:

```bash
nix build "github:lucernae/nix-config?dir=systems/nix-darwin/minimal#darwinConfigurations.minimal.system"
```

As a quick explanation the argument for `nix build` can be break apart like this:

**github**: Denotes the URI type. In this case, coming from a github repository.

**lucernae/nix-config**: The "*owner*/*repo*" format. By default will target default branch if the revision is not specified.

**dir=systems/nix-darwin/minimal**: The subdirectory in the repo branch/revision.

**darwinConfigurations.minimal.system**: The target output that we want to build.

Once the build finishes, there will be a symlink called `result` in the directory where you run the command.

### Tweak your configuration

Assuming you know either how NixOS or Nix-darwin works, you can define your own configuration. Usually it was called `configuration.nix`

To apply your configuration, use the rebuild command from the result symlink. In our case, let's try nix-darwin rebuild.

```bash
./result/sw/bin/darwin-rebuild switch
```

To edit the default configuration file, you can use your favorite editor to open the current configuration file.
For example, if you are using visual studio code:

```bash
EDITOR=code ./result/sw/bin/darwin-rebuild edit
```

Once you do a rebuild and switch, `darwin-rebuild` will be available in your shell. So you can also do this:

```bash
EDITOR=code darwin-rebuild edit
darwin-rebuild switch
```

If you are using flake, specify the flake URI location (can be from github or local path) to build your system.

```bash
darwin-rebuild switch --flake <URI>
```

## Glossary

System: a machine, setup, OS, or something that can be configured by nix. In this case, usually a system just means a 
computer, such as PC or laptop or raspberry pi. A system can have properties such as platform or architecture. Platform 
is like x86_64-linux (Linux based machine) or aarch64-darwin (macOS based machine). Platform usually identifies 
significant distinction such as the CPU architecture and the OS kernel/distribution. Linux based distro configured by Nix 
is called NixOS. As analogy, a nix based configured macOS is popularly called in the community as nix-darwin.

Nix: Nix is the software package manager, mainly focused on being declarative, reproducible, and reliable. Since nix 
is both refer to the software itself as a package manager and the declarative recipe as convention, nix theoritically can 
build anything as long as the recipe can be declared using Nix language.

Nix Flake: Current experimental feature of nix that adds hermeticity and enforce purity for describing software 
dependency. This make it possible to lock dependency and make it as pure as possible when we rebuild the recipe.
A nix flake also refer to the standardized schema of flakes so that software packages or flakes can be composed,
published, and shared easily.