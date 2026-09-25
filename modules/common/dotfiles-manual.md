% dotfiles 7 "" "dotfiles" "Dotfiles Configuration Manual"

# NAME

dotfiles - overview of this machine's Nix / home-manager configuration

# SYNOPSIS

**man dotfiles**

**setup-status** | **i3-keys** | **git-identity-setup** | **gcm-setup** | **x11-setup**

# DESCRIPTION

This machine is configured declaratively from a single Nix flake repository
(by default **~/dotfiles**). The user environment is managed by
**home-manager**; on Debian/Ubuntu hosts this runs *standalone* on top of the
distro (home-manager only manages files under **$HOME**), while the WSL host
also has a full NixOS system build.

Everything reproducible lives in the repo. The handful of things Nix cannot
provide on a non-NixOS host - secrets, and apt packages that need setuid - are
applied by the helper commands listed under **SETUP COMMANDS**, which are
themselves defined in the repo so the whole machine stays rebuildable.

This page is the map. For live, always-accurate detail (which changes when you
edit the config), it points you at commands rather than duplicating them here.

# PROFILES

Applied with **home-manager switch --flake ~/dotfiles#PROFILE** (PROFILE being
one of the names below):

*hm-debian*
: Debian workstation. Native i3, logged into via the display manager.

*hm-ubuntu*
: Ubuntu workstation.

*hm-wsl*
: Windows laptop (NixOS on WSL2). i3 in Xephyr.

*hm-crostini*
: Chromebook (Crostini). i3 in Xephyr, nixGL-wrapped media apps.

The WSL host also has a system build: **sudo nixos-rebuild switch --flake
~/dotfiles#nixos-wsl**.

# SETUP COMMANDS

*setup-status*
: Show first-time setup state and this machine's command list. Run it anytime;
it also prints a hint at login and after **home-manager switch** while anything
is still pending.

*git-identity-setup*
: Provision per-directory git name/email (**~/.config/git/identity-\***).

*gcm-setup*
: Set up the passphraseless GPG key and **pass** credential store used by Git
Credential Manager.

*x11-setup*
: (native-X profiles) Install apt xorg/xinit and i3lock+PAM, register the
"i3 (home-manager)" session with the display manager, and remove any apt i3.
Run once per machine.

# I3 WINDOW MANAGER

*i3-keys*
: List every i3 keybinding, parsed from the live generated config
(**~/.config/i3/config**) so it is always accurate. The modifier is the **Alt**
key. Bindings are grouped by mode (default, plus the emacs, resize and exit
modes).

The session is launched by the display manager through the **i3-session**
wrapper (**~/.nix-profile/bin/i3-session**), which puts the Nix profile on
PATH before starting i3 - this is why scripts such as the terminal launchers
resolve. Selecting a plain apt "i3" session instead would start i3 without the
Nix PATH and break those bindings.

Terminal launchers bound in i3: **term-urxvt** (Alt+Return), **term-xterm**
(Alt+Shift+Return) and **term-wezterm** (Alt+Ctrl+Return).

# FILES

*~/dotfiles*
: The configuration flake (this repo).

*~/dotfiles/modules/common*
: Shared modules, including i3, terminals, and this manual.

*~/.config/i3/config*
: The generated i3 config (read by **i3-keys**; do not edit by hand).

*/usr/local/share/xsessions/i3-hm.desktop*
: The display-manager session entry installed by **x11-setup**.

# SEE ALSO

**i3-keys**(1), **setup-status**(1), **i3**(1), **home-manager**(1)

The repository README covers new-machine bootstrap and updating other machines.
