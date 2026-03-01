# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

A Nix flake providing a reusable home-manager module for base quality-of-life setup on remote Linux machines (x86_64 and aarch64). It installs and configures: zsh, fzf, git, jujutsu, neovim, tmux, htop.

## Architecture

- `flake.nix` — Exposes two consumption paths:
  - `lib.mkHome { system, username, gitName, gitEmail }` — standalone homeManagerConfiguration
  - `homeModules.default` — composable home-manager module for use alongside other flakes
- `home.nix` — Single home-manager module defining all tools and config. Declares custom options under `hm-base` (`gitName`, `gitEmail`) which are required (no defaults — fail-fast).

## Usage

### Required inputs

| Parameter | Description |
|---|---|
| `system` | Target architecture: `x86_64-linux` or `aarch64-linux` |
| `username` | Linux user to configure (sets `home.username` and `home.homeDirectory` to `/home/<username>`) |
| `gitName` | Full name for git and jj commits |
| `gitEmail` | Email for git and jj commits |

### Standalone — `lib.mkHome`

Use when this is the only home-manager module needed:

```nix
{
  inputs = {
    hm-base.url = "github:iceberg-lab/nix-base";
  };

  outputs = { hm-base, ... }: {
    homeConfigurations."myuser" = hm-base.lib.mkHome {
      system = "x86_64-linux";
      username = "myuser";
      gitName = "My Name";
      gitEmail = "me@example.com";
    };
  };
}
```

Activate with: `home-manager switch --flake .#myuser`

### Composable — `homeModules.default`

Use when combining with other home-manager modules from other flakes:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    home-manager.url = "github:nix-community/home-manager";
    hm-base.url = "github:iceberg-lab/nix-base";
  };

  outputs = { nixpkgs, home-manager, hm-base, ... }: {
    homeConfigurations."myuser" = home-manager.lib.homeManagerConfiguration {
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
      modules = [
        hm-base.homeModules.default
        ./other-module.nix
        {
          home.username = "myuser";
          home.homeDirectory = "/home/myuser";
          hm-base.gitName = "My Name";
          hm-base.gitEmail = "me@example.com";
        }
      ];
    };
  };
}
```

### Post-activation

Home-manager cannot change the login shell (`/etc/passwd`). After first activation, run: `chsh -s $(which zsh)`

## Commands

```sh
# Check flake syntax and structure
nix flake check

# Evaluate a full configuration to verify it builds
nix eval .#lib.mkHome --apply 'f: (f { system = "x86_64-linux"; username = "testuser"; gitName = "Test"; gitEmail = "t@t.com"; }).activationPackage.drvPath'

# Update flake inputs
nix flake update
```

## Conventions

- Targets Linux only — `supportedSystems` is `x86_64-linux` and `aarch64-linux`.
- Uses `nixpkgs-unstable` and latest home-manager.
- No default values for required options — prefer fast failure over silent misconfiguration.
- Shell snippets in `initContent` use `''${var}` to escape Nix interpolation — when providing shell code for local testing, remove the `''` escaping.
