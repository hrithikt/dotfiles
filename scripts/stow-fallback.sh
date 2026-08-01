#!/usr/bin/env bash
#
# stow-fallback.sh — pure-bash replacement for `stow`, for the bootstrap case
# where the dotfiles need linking before Homebrew (and therefore stow) exists.
#
# Follows the same convention as stow: a package directory's contents mirror
# the path relative to $HOME, so zsh/.zshrc -> ~/.zshrc and
# ghostty/.config/ghostty/config -> ~/.config/ghostty/config.
#
# Differences from real stow, both deliberate:
#   * Links individual FILES, never whole directories. Real stow will symlink a
#     directory outright if the target does not exist, which means a tool later
#     writing into ~/.config/ghostty drops the new file inside the repo. Linking
#     per-file keeps the repo boundary clean.
#   * Conflicting regular files are moved aside to <path>.backup rather than
#     causing an abort.
#
# Usage:
#   ./scripts/stow-fallback.sh [--simulate] <package> [<package>...]
#
#   --simulate   print what would happen, touch nothing (mirrors stow -n)

set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TARGET="${STOW_TARGET:-$HOME}"
SIMULATE=0

if [[ "${1:-}" == "--simulate" || "${1:-}" == "-n" ]]; then
	SIMULATE=1
	shift
fi

if [[ $# -eq 0 ]]; then
	echo "usage: $0 [--simulate] <package> [<package>...]" >&2
	exit 1
fi

run() {
	if [[ $SIMULATE -eq 1 ]]; then
		echo "    WOULD: $*"
	else
		"$@"
	fi
}

linked=0
backed_up=0
skipped=0

for pkg in "$@"; do
	pkg_dir="$DOTFILES/$pkg"
	if [[ ! -d "$pkg_dir" ]]; then
		echo "  ! no such package: $pkg" >&2
		exit 1
	fi

	echo "  package: $pkg"

	# -print0 / read -d '' so paths with spaces survive.
	while IFS= read -r -d '' src; do
		rel="${src#"$pkg_dir"/}"
		dst="$TARGET/$rel"

		# Already the correct symlink? Nothing to do — this is what makes
		# re-running a no-op instead of piling up .backup files.
		if [[ -L "$dst" && "$(readlink "$dst")" == "$src" ]]; then
			skipped=$((skipped + 1))
			continue
		fi

		run mkdir -p "$(dirname "$dst")"

		# Anything real in the way gets preserved, never clobbered.
		if [[ -e "$dst" || -L "$dst" ]]; then
			echo "    backup: $dst -> $dst.backup"
			run mv "$dst" "$dst.backup"
			backed_up=$((backed_up + 1))
		fi

		echo "    link:   $dst -> $src"
		run ln -s "$src" "$dst"
		linked=$((linked + 1))
	done < <(find "$pkg_dir" -type f -print0)
done

echo
if [[ $SIMULATE -eq 1 ]]; then
	echo "  simulation only — nothing was changed"
fi
echo "  linked: $linked  backed up: $backed_up  already correct: $skipped"
