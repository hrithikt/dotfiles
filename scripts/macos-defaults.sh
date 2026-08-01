#!/usr/bin/env bash
#
# macos-defaults.sh — system settings captured from the source Mac.
#
# Every value below was read off the machine with `defaults read` / `defaults
# read-type`, not copied from someone else's opinionated dotfiles. Types match
# what macOS actually had stored, so re-applying is faithful.
#
# Keys that were NOT set on the source machine are listed commented-out at the
# end of each section, so you can see what was deliberately left at the system
# default rather than wondering whether it was forgotten.
#
# Captured on macOS 26.5.2 (arm64).
#
# Run directly, or via install.sh which prompts first:
#   ./scripts/macos-defaults.sh

set -euo pipefail

if [[ "$(uname -s)" != "Darwin" ]]; then
	echo "macos-defaults.sh: macOS only, refusing to run on $(uname -s)." >&2
	exit 1
fi

echo "Applying macOS defaults..."

# ---------------------------------------------------------------------------
# Dock
# ---------------------------------------------------------------------------

# Hide the Dock automatically; it slides in on hover.
defaults write com.apple.dock autohide -bool true

# Dock icon size in points.
defaults write com.apple.dock tilesize -float 64

# Not set on the source machine — left at the system default:
#   autohide-delay          how long before the hidden Dock appears
#   autohide-time-modifier  Dock slide-in animation speed
#   magnification           enlarge icons on hover
#   orientation             which screen edge the Dock sits on (default: bottom)
#   mineffect               minimise animation (genie / scale)
#   show-recents            trailing section of recently used apps
#   mru-spaces              auto-rearrange Spaces by most recent use

# ---------------------------------------------------------------------------
# Hot corners
#
# Corner actions: 0 = none, 2 = Mission Control, 3 = Application Windows,
# 4 = Desktop, 5 = Start Screen Saver, 6 = Disable Screen Saver, 7 = Dashboard,
# 10 = Put Display to Sleep, 11 = Launchpad, 12 = Notification Centre,
# 13 = Lock Screen, 14 = Quick Note.
# ---------------------------------------------------------------------------

# Bottom-right corner opens Quick Note.
defaults write com.apple.dock wvous-br-corner -int 14

# The matching modifier key is unset on the source machine, which means an
# implicit 0 — no modifier needed, the corner triggers on hover alone. Written
# explicitly so a machine with a stale non-zero modifier gets reset to match.
defaults write com.apple.dock wvous-br-modifier -int 0

# The other three corners have no action assigned:
#   wvous-tl-corner / wvous-tr-corner / wvous-bl-corner

# ---------------------------------------------------------------------------
# Finder
# ---------------------------------------------------------------------------

# Show hidden (dot-) files.
defaults write com.apple.finder AppleShowAllFiles -bool true

# Show the sidebar.
defaults write com.apple.finder ShowSidebar -bool true

# Default view style for new windows: icon view.
# (Others: "Nlsv" list, "clmv" column, "glyv" gallery.)
defaults write com.apple.finder FXPreferredViewStyle -string "icnv"

# What a new Finder window opens to: "PfAF" = All My Files / Recents.
# (Others: "PfHm" home, "PfDe" desktop, "PfDo" documents, "PfLo" a custom path.)
defaults write com.apple.finder NewWindowTarget -string "PfAF"

# Desktop icons: hide internal drives, show external drives and removable media.
defaults write com.apple.finder ShowHardDrivesOnDesktop -bool false
defaults write com.apple.finder ShowExternalHardDrivesOnDesktop -bool true
defaults write com.apple.finder ShowRemovableMediaOnDesktop -bool true

# Not set on the source machine — left at the system default:
#   ShowPathbar / ShowStatusBar         path and status bars at window bottom
#   FXDefaultSearchScope                search this Mac vs current folder
#   FXEnableExtensionChangeWarning      warn when changing a file extension
#   _FXSortFoldersFirst                 sort folders above files
#   _FXShowPosixPathInTitle             full POSIX path in the title bar
#   WarnOnEmptyTrash                    confirm before emptying Trash
#   ShowMountedServersOnDesktop         network volumes on the desktop

# ---------------------------------------------------------------------------
# Screenshots
# ---------------------------------------------------------------------------

# Screenshots go to the clipboard rather than being written to disk.
defaults write com.apple.screencapture target -string "clipboard"

# NOTE: `location` is deliberately NOT set on the source machine. With
# target=clipboard there is no file to place, so the save folder never applies.
# If you switch target back to "file", uncomment and point this somewhere:
#   defaults write com.apple.screencapture location -string "$HOME/Screenshots"
#
# Also unset, left at the system default:
#   type            image format (png default)
#   disable-shadow  drop shadow on window captures
#   show-thumbnail  floating thumbnail after capture

# ---------------------------------------------------------------------------
# Keyboard
# ---------------------------------------------------------------------------

# Key repeat rate: 1 is the fastest value the slider exposes.
defaults write -g KeyRepeat -int 1

# Delay before a held key starts repeating: 10 is a short delay.
defaults write -g InitialKeyRepeat -int 10

# Text substitutions that are ON on the source machine.
defaults write -g NSAutomaticCapitalizationEnabled -bool true
defaults write -g NSAutomaticPeriodSubstitutionEnabled -bool true

# Dark appearance.
defaults write -g AppleInterfaceStyle -string "Dark"

# Spring-loaded folders: drag a file onto a folder and it opens.
defaults write -g "com.apple.springing.enabled" -bool true

# NOTE: ApplePressAndHoldEnabled is deliberately NOT set. Unset means the system
# default (enabled), so holding a key shows the accent/diacritic menu rather
# than repeating the character. Uncomment only if you want key repeat on hold:
#   defaults write -g ApplePressAndHoldEnabled -bool false
#
# Also unset, left at the system default:
#   AppleKeyboardUIMode                     full keyboard access / tab to controls
#   NSAutomaticSpellingCorrectionEnabled    autocorrect
#   NSAutomaticDashSubstitutionEnabled      smart dashes
#   NSAutomaticQuoteSubstitutionEnabled     smart quotes
#   AppleShowAllExtensions                  always show file extensions
#   com.apple.keyboard.fnState              F-keys as standard function keys
#   com.apple.swipescrolldirection          natural scroll direction

# ---------------------------------------------------------------------------
# Trackpad
#
# Two domains are written because macOS keeps built-in and external Bluetooth
# trackpads separate. Both were configured identically on the source machine.
# ---------------------------------------------------------------------------

# Force Touch enabled.
defaults write -g "com.apple.trackpad.forceClick" -bool true

# --- Built-in trackpad ---
# Tap to click.
defaults write com.apple.AppleMultitouchTrackpad Clicking -bool true
# Tap-and-a-half drag.
defaults write com.apple.AppleMultitouchTrackpad Dragging -bool true
# Two-finger tap for secondary (right) click.
defaults write com.apple.AppleMultitouchTrackpad TrackpadRightClick -bool true
# Three-finger drag OFF (three fingers swipe between spaces instead).
defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerDrag -bool false
# Three-finger tap (look up / data detectors) OFF.
defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerTapGesture -int 0
# Corner-click for secondary click OFF (using two-finger tap instead, above).
defaults write com.apple.AppleMultitouchTrackpad TrackpadCornerSecondaryClick -int 0
# Click pressure thresholds: 1 = medium (0 light, 2 firm).
defaults write com.apple.AppleMultitouchTrackpad FirstClickThreshold -int 1
defaults write com.apple.AppleMultitouchTrackpad SecondClickThreshold -int 1

# --- External Bluetooth trackpad (Magic Trackpad) ---
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadRightClick -bool true
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadThreeFingerDrag -bool false
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadThreeFingerTapGesture -int 0
# Two-finger double-tap for smart zoom — ON here, and only set on this domain.
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadTwoFingerDoubleTapGesture -int 1

# NOTE: com.apple.mouse.tapBehavior is NOT set on the source machine. Some
# guides set it to 1 to make tap-to-click stick across logins; it was not
# needed here, so it stays unset:
#   defaults write -g com.apple.mouse.tapBehavior -int 1
#
# Also unset, left at the system default:
#   ActuationStrength           silent clicking
#   com.apple.trackpad.scaling  tracking speed

# ---------------------------------------------------------------------------
# Apply
# ---------------------------------------------------------------------------

echo "Restarting affected apps..."
for app in Dock Finder SystemUIServer; do
	killall "$app" >/dev/null 2>&1 || true
done

echo
echo "Done. Some settings only take effect after a logout or restart —"
echo "key repeat rate and trackpad thresholds in particular."
