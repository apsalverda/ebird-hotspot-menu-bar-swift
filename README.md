# eBird Hotspot Menu Bar

A lightweight macOS menu bar app that displays recent bird observations from a specific eBird hotspot.

<img width="256" height="256" alt="icon_128x128@2x" src="https://github.com/user-attachments/assets/7a44d4c9-737b-4ce9-9c9f-48289e5fb02c" />


## What it does

The app sits in your menu bar and shows you the latest bird sightings at a hotspot of your choice, pulled directly from the eBird API. Click the bird icon to see a list of recent observations grouped by date (today, yesterday, and earlier), along with a species count for the last two weeks.

## Screenshot

<img width="1197" height="779" alt="ebird-hotspot-menubar-swift-screenshot" src="https://github.com/user-attachments/assets/7a5bcfa7-dfc4-4f36-bed6-523de237f58a" />

## Features

- Shows recent observations for any eBird hotspot by location ID (e.g. `L4686222`)
- Store up to 10 hotspots, with an optional default hotspot
- Access a hotspot's ebird page by clicking on the link icon 🔗
- Groups observations by today, yesterday, and earlier
- Displays species count for the last two weeks
- Optionally shows the number of birds per observation
- Refreshes automatically every time you click the icon
- API key stored securely in the macOS Keychain

## Requirements

- macOS 13 (Ventura) or later
- A free [eBird account](https://ebird.org) and [API key](https://ebird.org/api/keygen)
- Xcode 15 or later (to build from source)

## Setup

If you have not used XCode before:

1. [Download](https://apps.apple.com/us/app/xcode/id497799835) XCode
2. When you first open the XCode, make sure to install macOS platform components
3. Configure your Apple ID: Xcode->Settings->Accounts and add your Apple account

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
