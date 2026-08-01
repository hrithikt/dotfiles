#!/usr/bin/env bash
#
# scan-secrets.sh — grep the repo (or the staged set) for credential-shaped and
# employer-specific strings before anything is committed or pushed.
#
# This is a safety net, not a guarantee. It catches the common shapes; it will
# not catch a secret that looks like ordinary prose.
#
# Usage:
#   ./scripts/scan-secrets.sh            # scan tracked + staged files
#   ./scripts/scan-secrets.sh --all      # scan every file in the repo

# No `set -u`: bash 3.2 treats expanding an empty array as an unbound variable,
# and the file list is legitimately empty before the first `git add`.
set -o pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$DOTFILES"

# Credential shapes: provider-prefixed tokens, private keys, AWS keys, and
# long hex/base64 runs that look like an API token.
SECRET_PAT='ghp_[A-Za-z0-9]{16,}|gho_[A-Za-z0-9]{16,}|ghs_[A-Za-z0-9]{16,}|github_pat_[A-Za-z0-9_]{20,}|sk-[A-Za-z0-9_-]{20,}|AKIA[0-9A-Z]{16}|ASIA[0-9A-Z]{16}|xox[baprs]-[A-Za-z0-9-]{10,}|-----BEGIN [A-Z ]*PRIVATE KEY-----|AIza[0-9A-Za-z_-]{35}|glpat-[A-Za-z0-9_-]{20,}|[A-Fa-f0-9]{40,}|(api[_-]?key|secret|passwd|password|token)[[:space:]]*[=:][[:space:]]*["'"'"']?[A-Za-z0-9/+_-]{16,}'

# Employer / internal-infrastructure shapes.
EMPLOYER_PAT='baserock|BaseRock|BASEROCK|\.internal\b|\.corp\b|\bvpn\b|artifactory|jfrog|nexus\.|registry\.[a-z0-9-]+\.(com|io|net)/|10\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}|192\.168\.[0-9]{1,3}\.[0-9]{1,3}|172\.(1[6-9]|2[0-9]|3[01])\.[0-9]{1,3}\.[0-9]{1,3}'

# Built with a read loop rather than `mapfile`: macOS ships bash 3.2, which
# has no mapfile, and this repo has to bootstrap a stock Mac.
FILES=()
if [[ "${1:-}" == "--all" ]]; then
	while IFS= read -r line; do FILES+=("$line"); done < <(find . -type f -not -path './.git/*' | sort)
	echo "Scanning all ${#FILES[@]} files in the repo"
else
	while IFS= read -r line; do FILES+=("$line"); done < <(git ls-files --cached --others --exclude-standard | sort)
	echo "Scanning ${#FILES[@]} tracked/staged files"
fi
echo

status=0

scan() {
	local label="$1" pattern="$2" found=0
	echo "=============================================================="
	echo " $label"
	echo "=============================================================="
	for f in "${FILES[@]}"; do
		[[ -f "$f" ]] || continue
		# Skip this script — it necessarily contains the patterns themselves.
		[[ "$f" == *"scan-secrets.sh" ]] && continue
		local hits
		hits=$(grep -nEI "$pattern" "$f" 2>/dev/null)
		if [[ -n "$hits" ]]; then
			found=1
			echo "  $f"
			echo "$hits" | sed 's/^/      /'
		fi
	done
	if [[ $found -eq 0 ]]; then
		echo "  clean — no matches"
	else
		status=1
	fi
	echo
}

scan "SWEEP 1 — credential shapes" "$SECRET_PAT"
scan "SWEEP 2 — employer-specific shapes" "$EMPLOYER_PAT"

if [[ $status -ne 0 ]]; then
	echo "Matches found. Review each one — some may be false positives"
	echo "(a comment, a placeholder, a colour hex). Do not commit until clear."
else
	echo "Both sweeps clean."
fi

exit $status
