# eBird Hotspot Menu Bar

A lightweight macOS menu bar app that displays recent bird observations from a specific eBird hotspot.

## What it does

The app sits in your menu bar and shows you the latest bird sightings at a hotspot of your choice, pulled directly from the eBird API. Click the bird icon to see a list of recent observations grouped by date (today, yesterday, and earlier), along with a species count for the last two weeks.

## Features

- Shows most recently observed species for any eBird hotspot, by location ID (e.g. `L4686222`)
- Displays most recent observation for each species in the last two weeks
- Optionally shows the number of birds for each observation
- Provides total species count, and separate counts for today, yesterday, and earlier
- Allows to store up to 10 hotspots, and set default hotspot
- Access a hotspot's ebird page by clicking on the link icon 🔗
- Export data by clicking on the export icon
- Personal eBird API key stored securely in the macOS Keychain

## Requirements

- macOS 13 (Ventura) or later
- A free [eBird account](https://ebird.org) and [API key](https://ebird.org/api/keygen)
- Xcode 15 or later (to build from source)

## Setup

### Option 1: Download and install the  app

1. Download and unzip `ebird-hotspot-menubar.zip`
2. Move `ebird-hotspot-menubar.app` to your **Applications** folder
3. Double-click the app. macOS will show a warning saying the app is from an unidentified developer
4. Click **Cancel** on the dialog
5. Open **System Settings → Privacy & Security**
6. Scroll down to the **Security** section, where you should see a message saying the app was blocked
7. Click **Open Anyway**
8. Click **Open** in the confirmation dialog that appears

You only need to do this once. After that, the app will open normally.

### Option 2: Build from source

If you have not used XCode before:

1. [Download](https://apps.apple.com/us/app/xcode/id497799835) XCode
2. When you first open XCode, make sure to install macOS platform components
3. Configure your Apple ID: **Xcode → Settings → Accounts**, and add your Apple account

Download and compile the source code:

1. Clone the repository and open `ebird-hotspot-menubar.xcodeproj` in Xcode
2. Build and run the app (⌘R)

Using the app:

1. Click the bird icon in the menu bar
2. Click the gear icon to open Settings
3. Enter your eBird API key and the location IDs of your hotspots
4. Click Save

To find a hotspot's location ID, go to the hotspot's page on [ebird.org](https://ebird.org) — the ID is the `L` followed by a number in the URL (e.g. `L4686222`). You can also paste the URL into the location ID field in Settings.

## Built with

- Swift & SwiftUI
- AppKit (`NSStatusItem`, `NSPopover`)
- eBird API v2
- macOS Keychain Services
