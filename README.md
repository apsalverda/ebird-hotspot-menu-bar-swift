# eBird Hotspot Menu Bar

A lightweight macOS menu bar app that displays recent bird observations from a specific eBird hotspot.

## What it does

The app sits in your menu bar and shows you the latest bird sightings at a hotspot of your choice, pulled directly from the eBird API. Click the bird icon to see a list of recent observations grouped by date (today, yesterday, and earlier), along with a species count for the last two weeks.

## Screenshot

<img width="1470" height="956" alt="ebird-hotspot-menubar-swift-screenshot" src="https://github.com/user-attachments/assets/c39ccc3a-3bce-4482-b4d3-cfd98f25d0c8" />

## Features

- Shows recent observations for any eBird hotspot by location ID (e.g. `L4686222`)
- Displays species count for the last two weeks
- Optionally shows the number of birds per observation
- Groups observations by today, yesterday, and earlier
- Store up to 10 hotspots, with an optional default hotspot
- Access a hotspot's ebird page by clicking on the link icon 🔗
- Export data by clicking on the export icon
- eBird API key stored securely in the macOS Keychain

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

Download the source code:

1. Clone the repository and open `ebird-hotspot-menubar.xcodeproj` in Xcode
2. Build and run the app (⌘R)
3. Click the bird icon in the menu bar
4. Click the gear icon to open Settings
5. Enter your eBird API key and the location IDs of your hotspots
6. Click Save

To find a hotspot's location ID, go to the hotspot's page on [ebird.org](https://ebird.org) — the ID is the `L` followed by a number in the URL (e.g. `L4686222`). You can also paste the URL into the location ID field in Settings.

## Built with

- Swift & SwiftUI
- AppKit (`NSStatusItem`, `NSPopover`)
- eBird API v2
- macOS Keychain Services
