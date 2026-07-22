# Dotfiles

Personal development environment managed with [Nix](https://nixos.org) and
[Home Manager](https://github.com/nix-community/home-manager), shared across
three machines:

| Profile       | Machine                        | Extras on top of the common base                     |
|---------------|--------------------------------|------------------------------------------------------|
| `hm-wsl`      | Windows laptop (NixOS on WSL2) | i3 in Xephyr, screenshots, wsl-vpnkit VPN routing    |
| `hm-crostini` | Chromebook (Crostini)          | i3 in Xephyr, nixGL-wrapped media apps (VLC, Kodi)   |
| `hm-debian`   | Debian workstation             | Native i3 via `startx`/`.xinitrc`, screenshots       |

All three import [`home-manager/hm-common.nix`](./home-manager/hm-common.nix):
zsh (fzf, zoxide, bat, eza, and friends), git with per-directory identities,
Emacs, terminals (xterm/urxvt/wezterm), fonts, and language tooling for
Clojure, Node.js, Rust, Docker, devcontainers, AWS, and Claude Code.

## Applying a configuration

```sh
home-manager switch --flake ~/dotfiles#hm-wsl      # or #hm-crostini / #hm-debian
```

There is also a full NixOS system build for the WSL host:

```sh
sudo nixos-rebuild switch --flake ~/dotfiles#nixos-wsl
```

## New machine bootstrap

1. Install Nix (with flakes enabled) and clone this repo to `~/dotfiles`.
2. `nix run home-manager -- switch --flake ~/dotfiles#<profile>`
3. `git-identity-setup` — provisions per-machine git identities (see below).
4. `gcm-setup` — GPG key + password store for Git Credential Manager.
5. Debian only: `debian-setup` installs the system packages Nix can't
   provide (xorg, xinit, i3lock with setuid).

## Updating the other machines

Normal flow after pushing changes from one machine:

```sh
cd ~/dotfiles
git pull
home-manager switch --flake .#<profile>
```

After a **history rewrite** (force push), `git pull` will refuse or produce
merge conflicts because the histories have diverged. Reset the clone to the
rewritten remote instead — local identity files under `~/.config/git/` are
untouched by this:

```sh
cd ~/dotfiles
git fetch origin
git reset --hard origin/master
home-manager switch --flake .#<profile>
```

If `git-identity-setup` has not been run on the machine yet, run it after
switching — commits are refused until the identity files exist.

## Git identities

No identity is set globally (`user.useConfigOnly`); git refuses to commit
unless a directory rule matches:

| Directory     | Identity file (untracked, per-machine) |
|---------------|----------------------------------------|
| `~/dotfiles/` | `~/.config/git/identity-personal`      |
| `~/projects/` | `~/.config/git/identity-work`          |

Run `git-identity-setup` once per machine to create them. Email addresses
never appear in this repository; use your GitHub noreply address for the
personal identity.

## Layout

```
flake.nix              Inputs, the three HM profiles, nixos-wsl host, checks
home-manager/          Per-machine profiles + hm-common.nix shared base
modules/common/        Modules imported by the profiles
  applications/        age secrets, chrome, i3/Xephyr, screenshots, vpnkit...
  programming/         clojure, nodejs, rust, docker, claudecode...
  shell.nix, git.nix, emacs.nix, terminals.nix, fonts.nix
hosts/nixos-wsl/       Full NixOS system config for the WSL host
overlays/              emacs packages, awscli fix, wsl-vpnkit
apps/restartx.nix      Xephyr restart helper used by the i3 setup
templates/             `nix flake init -t` project starters
```

## Maintenance

```sh
nix flake check --no-build   # verify every profile still evaluates
nix flake check              # additionally build all three profiles
nix flake update             # bump inputs
nix fmt                      # format nix files
```

History note: this repo started as a fork of
[nmasur/dotfiles](https://github.com/nmasur/dotfiles) and was later slimmed
down to the Home Manager-only setup described above. Removed machinery
(NixOS homelab services, macOS support, neovim config, ...) is recoverable
from git history (`pre-cleanup` tag).
