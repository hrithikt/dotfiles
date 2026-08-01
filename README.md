# dotfiles

macOS setup — packages, shell, terminal stack, and system settings — reproducible on a new machine.

Managed with [GNU Stow](https://www.gnu.org/software/stow/): each top-level directory is a *package* whose contents mirror the path relative to `$HOME`. So `zsh/.zshrc` becomes `~/.zshrc`, and `ghostty/.config/ghostty/config` becomes `~/.config/ghostty/config`.

Captured from macOS 26.5.2 on Apple Silicon.

---

## New machine quickstart

Run these in order on a fresh Mac.

**1. Command Line Tools** — everything else depends on `git`.

```bash
xcode-select --install
```

Wait for the GUI installer to finish before continuing.

**2. SSH key for GitHub.** The repo is private, so you need auth before you can clone. Either copy `~/.ssh/id_ed25519_personal` across from the old machine, or generate a fresh one:

```bash
ssh-keygen -t ed25519 -C "hrithikt1999@gmail.com" -f ~/.ssh/id_ed25519_personal
```

**3. Minimal SSH config** so the `github-personal` host alias resolves. This is a bootstrap stub; the full template gets copied in step 6.

```bash
printf 'Host github-personal\n  HostName github.com\n  User git\n  AddKeysToAgent yes\n  UseKeychain yes\n  IdentitiesOnly yes\n  IdentityFile ~/.ssh/id_ed25519_personal\n' >> ~/.ssh/config
chmod 600 ~/.ssh/config
```

Add the public key at <https://github.com/settings/keys>, then verify:

```bash
ssh -T git@github-personal
```

Expect `Hi hrithikt!`.

**4. Clone.**

```bash
git clone git@github-personal:hrithikt/dotfiles.git ~/dotfiles
```

**5. Install.** Installs Homebrew if missing, runs `brew bundle`, links every package, restores Rectangle, and asks before touching system settings.

```bash
cd ~/dotfiles && ./install.sh
```

Sign in to the App Store first if you want the `mas` entries to install.

**6. Finish the manual steps** that `install.sh` prints — SSH config template, git identity, `~/.zshrc.local`, Raycast cloud sync. They are listed in [Manual steps](#manual-steps) below.

**7. Restart.** Key repeat and trackpad thresholds only fully apply after a logout.

---

## What is in here

| Package | Links to | Contents |
|---|---|---|
| `zsh/` | `~/.zshrc`, `~/.zprofile`, `~/.zshenv` | PATH, pyenv, nvm, starship, zoxide, atuin, bun, eza aliases |
| `git/` | `~/.gitconfig`, `~/.config/git/ignore` | credential helper, global ignore |
| `ghostty/` | `~/.config/ghostty/` | terminal config + `verminal` theme |
| `zellij/` | `~/.config/zellij/config.kdl` | full custom keybindings |
| `atuin/` | `~/.config/atuin/config.toml` | shell history search |
| `starship/` | `~/.config/starship.toml` | prompt |
| `btop/` | `~/.config/btop/btop.conf` | resource monitor |
| `ssh/` | *not linked* | `config.template` — copied by hand, see below |
| `rectangle/` | *not linked* | exported prefs, imported by `install.sh` |
| `scripts/` | — | `macos-defaults.sh`, `stow-fallback.sh`, `scan-secrets.sh` |

`ssh/` is intentionally **not** stowed. Symlinking `~/.ssh/config` into a git repo can trip SSH's strict permission checks and clobber a working file, so it is copied manually instead.

### Adding a package later

```bash
mkdir -p newtool/.config/newtool
cp ~/.config/newtool/config newtool/.config/newtool/config
stow --target="$HOME" newtool
```

Then add it to `PACKAGES` in `install.sh`.

---

## Manual steps

### Git identity

`.gitconfig` deliberately ships with **no `[user]` block**. The source machine had an employer identity as the global default; that should not silently follow you. Set it explicitly:

```bash
git config --global user.name  "Your Name"
git config --global user.email "you@example.com"
```

### Two GitHub accounts

Work and personal accounts are kept apart by SSH host alias, not by `gh auth switch` — the alias determines which key is offered, so pushes are deterministic. Copy the template and rename the work alias to suit:

```bash
cp ~/dotfiles/ssh/.ssh/config.template ~/.ssh/config
chmod 600 ~/.ssh/config
```

Always use the alias in remotes, never bare `git@github.com:`, which picks whichever key SSH happens to try first:

```bash
git remote set-url origin git@github-personal:hrithikt/<repo>.git
```

### Machine-local shell config

Anything employer-specific — internal tooling, VPN helpers, private registry auth, work git identity — belongs in `~/.zshrc.local`, which is gitignored and sourced from the end of `~/.zshrc`:

```bash
cp ~/dotfiles/zshrc.local.example ~/.zshrc.local
```

This repo is deliberately job-portable. Work aliases from the source machine were left out of it on purpose, not by oversight.

### Raycast

**Do not sync Raycast config through this repo.** Raycast keeps its state in a sqlite store that does not survive being copied between machines — you get a corrupted or silently reset configuration.

Raycast has built-in cloud sync, and that is the right path:

> **Raycast → Settings → Advanced → Cloud Sync** → enable, and sign in with the same account on the new machine.

That covers extensions, aliases, hotkeys, quicklinks, snippets, and window-management settings. Nothing further is needed here.

### Rectangle

Settings are exported to `rectangle/com.knollsoft.Rectangle.plist` and imported by `install.sh`. Volatile keys (Sparkle updater state, saved window frames) are stripped so the file stays diff-stable.

To re-export after changing settings:

```bash
defaults export com.knollsoft.Rectangle - > /tmp/rect.plist
# then strip the volatile keys before committing
```

To restore by hand:

```bash
killall Rectangle
defaults import com.knollsoft.Rectangle ~/dotfiles/rectangle/com.knollsoft.Rectangle.plist
open -a Rectangle
```

---

## macOS system settings

`scripts/macos-defaults.sh` writes Dock, Finder, trackpad, keyboard, screenshot, and hot-corner settings. `install.sh` runs it only after you confirm; it can also be run standalone.

Every value was read off the source machine with `defaults read`. Keys that were *not* set are listed commented-out in the script, so you can tell "deliberately left at the system default" from "forgotten". Notable captured settings:

- Dock auto-hides, icon size 64
- Bottom-right hot corner → Quick Note
- Finder shows hidden files, icon view, external drives on desktop but not internal
- **Screenshots go to the clipboard, not to a file**
- Fastest key repeat, short initial delay
- Tap to click, two-finger secondary click, three-finger drag off
- Dark appearance

---

## Manual installs

`brew bundle` covers formulae, casks, Mac App Store apps, and VS Code extensions. These were installed outside Homebrew on the source machine and need re-downloading by hand:

**Browsers & comms** — Google Chrome, Zen, Discord, Spotify
**AI & editors** — Claude, ChatGPT, Visual Studio Code, IntelliJ IDEA CE, JetBrains Toolbox, OpenCode, Kaze, Moss, Readout
**Dev tools** — Docker Desktop, Postman, MongoDB Compass, pgAdmin 4, Python 3.12 / 3.14 (python.org installers)
**Notes & productivity** — Notion, Notion Calendar, Obsidian, TimeMaster, Opal
**Audio & capture** — Wispr Flow, FluidVoice, Helmer Micro, meetily
**Google** — Earth Pro, plus the Docs/Sheets/Slides web shortcuts
**Other** — Hyper (superseded by Ghostty), Avira Security

Mac App Store apps *are* in the Brewfile (Pages, Numbers, Keynote, GarageBand, iMovie, WhatsApp, Prime Video) but need you signed in to the App Store before `brew bundle install` can fetch them.

Anything installed by an employer's MDM or compliance tooling is intentionally not listed here — that gets reinstalled through the employer, not from this repo.

---

## Safety

`scripts/scan-secrets.sh` greps tracked and staged files for credential shapes (provider tokens, private keys, AWS keys, long hex runs) and for employer-specific strings (company names, internal hostnames, private registries, RFC-1918 addresses).

```bash
./scripts/scan-secrets.sh          # tracked + staged
./scripts/scan-secrets.sh --all    # everything in the repo
```

Exits non-zero on a match. Worth running before every push. It is a safety net, not a guarantee — it catches shapes, not secrets that look like prose.

`.gitignore` excludes SSH private keys, `.env` files, API tokens, AWS/GCP/Azure credentials, kubeconfig, `gh`'s `hosts.yml`, the atuin sync key and history databases, and `~/.zshrc.local`.

---

## Re-running

`install.sh` is idempotent. Paths that are already the correct symlink are skipped, so a second run creates no new `*.backup` files and changes nothing. Conflicting real files are moved to `<path>.backup` rather than being overwritten.
