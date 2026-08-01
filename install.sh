#!/usr/bin/env bash
#
# install.sh — reproduce this Mac from a fresh install.
#
# Idempotent and safe to re-run: already-correct symlinks are left alone, so a
# second run creates no new .backup files and changes nothing.
#
# Written for stock macOS bash 3.2 — no mapfile, no associative arrays.
#
#   ./install.sh
#
# Steps:
#   1. install Homebrew if missing
#   2. brew bundle install
#   3. stow every package (conflicts moved to <path>.backup)
#   4. restore Rectangle's settings
#   5. macOS system defaults — behind a confirmation prompt
#   6. print the manual steps that cannot be automated

set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Every stow package. `ssh` is deliberately absent — see step 6.
PACKAGES="zsh git ghostty zellij atuin starship btop"

bold() { printf '\033[1m%s\033[0m\n' "$*"; }
step() { printf '\n\033[1;34m==>\033[0m \033[1m%s\033[0m\n' "$*"; }
warn() { printf '\033[1;33m  ! %s\033[0m\n' "$*"; }

# ---------------------------------------------------------------------------
# Guards
# ---------------------------------------------------------------------------

if [[ "$(uname -s)" != "Darwin" ]]; then
	echo "install.sh: macOS only, refusing to run on $(uname -s)." >&2
	exit 1
fi

if [[ "$(id -u)" -eq 0 ]]; then
	echo "install.sh: do not run as root. Homebrew refuses it and the symlinks" >&2
	echo "would land in /var/root instead of your home directory." >&2
	exit 1
fi

bold "Dotfiles: $DOTFILES"
bold "Target:   $HOME"

# ---------------------------------------------------------------------------
# 1. Homebrew
# ---------------------------------------------------------------------------

step "Homebrew"

if command -v brew >/dev/null 2>&1; then
	echo "  already installed: $(command -v brew)"
else
	echo "  installing..."
	/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Put brew on PATH for the rest of this script regardless of shell config,
# covering both Apple Silicon and Intel prefixes.
if [[ -x /opt/homebrew/bin/brew ]]; then
	eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x /usr/local/bin/brew ]]; then
	eval "$(/usr/local/bin/brew shellenv)"
fi

# ---------------------------------------------------------------------------
# 2. Packages
# ---------------------------------------------------------------------------

step "Homebrew bundle"

# Mac App Store entries need you signed in to the App Store app first; mas
# cannot authenticate on your behalf and those lines will fail otherwise.
if ! mas account >/dev/null 2>&1; then
	warn "Not signed in to the App Store — 'mas' entries in the Brewfile will fail."
	warn "Sign in via the App Store app and re-run to pick them up."
fi

echo "  brew bundle install (this takes a while on a fresh machine)..."
brew bundle install --file="$DOTFILES/Brewfile"

# ---------------------------------------------------------------------------
# 3. Stow
# ---------------------------------------------------------------------------

step "Linking dotfiles"

# Move anything real that sits where a symlink needs to go. Paths that are
# already the correct symlink are skipped, which is what keeps re-runs clean.
backed_up=0
for pkg in $PACKAGES; do
	pkg_dir="$DOTFILES/$pkg"
	[[ -d "$pkg_dir" ]] || continue
	while IFS= read -r -d '' src; do
		rel="${src#"$pkg_dir"/}"
		dst="$HOME/$rel"
		if [[ -L "$dst" && "$(readlink "$dst")" == "$src" ]]; then
			continue
		fi
		if [[ -e "$dst" || -L "$dst" ]]; then
			echo "  backup: $dst -> $dst.backup"
			mv "$dst" "$dst.backup"
			backed_up=$((backed_up + 1))
		fi
	done < <(find "$pkg_dir" -type f -print0)
done
echo "  files moved aside: $backed_up"

if command -v stow >/dev/null 2>&1; then
	for pkg in $PACKAGES; do
		[[ -d "$DOTFILES/$pkg" ]] || continue
		echo "  stow: $pkg"
		stow --dir="$DOTFILES" --target="$HOME" --restow "$pkg"
	done
else
	warn "stow not found — using scripts/stow-fallback.sh"
	# shellcheck disable=SC2086
	"$DOTFILES/scripts/stow-fallback.sh" $PACKAGES
fi

# ---------------------------------------------------------------------------
# 4. Rectangle
# ---------------------------------------------------------------------------

step "Rectangle settings"

RECT_PLIST="$DOTFILES/rectangle/com.knollsoft.Rectangle.plist"

if [[ ! -f "$RECT_PLIST" ]]; then
	warn "no plist at $RECT_PLIST — skipping"
elif [[ ! -d /Applications/Rectangle.app ]]; then
	warn "Rectangle.app not installed yet — skipping."
	warn "Re-run install.sh after 'brew install --cask rectangle' completes."
else
	# Rectangle must not be running, or it rewrites the domain from memory on
	# quit and undoes the import.
	killall Rectangle >/dev/null 2>&1 || true
	sleep 1
	defaults import com.knollsoft.Rectangle "$RECT_PLIST"
	echo "  imported settings from $RECT_PLIST"
	open -a Rectangle 2>/dev/null || warn "could not relaunch Rectangle"
fi

# ---------------------------------------------------------------------------
# 5. macOS defaults (opt-in)
# ---------------------------------------------------------------------------

step "macOS system defaults"

echo "  This rewrites Dock, Finder, trackpad, keyboard, screenshot and hot-corner"
echo "  settings to match the source machine, then restarts Dock and Finder."
echo "  See scripts/macos-defaults.sh for exactly what it writes."
echo
read -r -p "  Apply macOS system defaults? [y/N] " reply
case "$reply" in
	[yY] | [yY][eE][sS])
		"$DOTFILES/scripts/macos-defaults.sh"
		;;
	*)
		echo "  skipped — run ./scripts/macos-defaults.sh later if you change your mind"
		;;
esac

# ---------------------------------------------------------------------------
# 6. Manual steps
# ---------------------------------------------------------------------------

step "Done — remaining manual steps"

cat <<'EOF'
  These cannot be automated safely:

  1. SSH keys — no private keys are in this repo. Either copy
     ~/.ssh/id_ed25519* from the old machine, or generate new ones and add the
     public halves to the matching GitHub accounts.

  2. SSH config — copy the template and rename the work host alias:
       cp ~/dotfiles/ssh/.ssh/config.template ~/.ssh/config
       chmod 600 ~/.ssh/config
     Then verify:  ssh -T git@github-personal

  3. Git identity — .gitconfig ships with no [user] block on purpose:
       git config --global user.name  "Your Name"
       git config --global user.email "you@example.com"

  4. Machine-local shell config — work aliases and anything employer-specific:
       cp ~/dotfiles/zshrc.local.example ~/.zshrc.local
     Then edit it. ~/.zshrc.local is gitignored and never enters this repo.

  5. Raycast — do NOT copy config files. Open Raycast, then
     Settings -> Advanced -> Cloud Sync and sign in. Its state is a sqlite
     store that does not survive being copied between machines.

  6. Apps not covered by Homebrew — see the "Manual installs" section of
     README.md for the current list.

  7. Restart, or at least log out and back in, so key repeat and trackpad
     settings take effect.
EOF
