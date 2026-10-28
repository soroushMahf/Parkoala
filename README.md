# Parkoala

Parkoala is an iOS app that helps drivers keep track of their parking by starting a timed parking session, get reminded before it expires, check whether a parking sign actually allows you to stay, find nearby car parks with live availability, and keep track of what parking has cost you over time.

## Features

- **Timed parking sessions:** Start a session with a duration (and an optional rate), watch a live countdown on the Park tab, and end it whenever suited to your parking time.
- **Live Activity & Lock Screen countdown:** An ActivityKit Live Activity (via `ParkoalaWidgets`) shows the time remaining on the Lock Screen and Dynamic Island while a session is active.
- **Expiry reminders:** Local notifications fire 15 and 5 minutes before a session expires, and are cancelled automatically if the session ends early.
- **Nearby car parks**: A map of nearby car parks sourced from the live TfNSW Car Park API, merged with saved locations and deduplicated by distance.
- **"Can I park here?"**: Enter the details off a parking sign (time limit, restricted hours, days) and get a yes or no answer on whether you can park now and when you'd need to move by.
- **Parking cost tracking:** Automatic cost estimates when a session ends with a known rate, plus a Money tab to add a rate/estimate or log the actual amount charged for sessions that don't have one yet, with monthly spending totals.
- **Session history**: Past sessions grouped by month, with duration, time range, rate, and cost for each.
- **Find My Car:** Save where you parked (map pin and/or level & bay) and get directions back to it.
- **Offline-friendly persistence:** Sessions and vehicles are stored locally on-device with SwiftData, so your data is there even without a connection.

## Requirements
- Xcode 16 or later
- iOS 18.6+ (simulator or device)
- A free TfNSW Open Data API key (see steps below) as the app still builds and runs without one, but the Nearby tab won't be able to show live car park data

## Getting started
1. Clone the repo and open `Parkoala.xcodeproj` in Xcode.
2. Set up your TfNSW API key (see [Connecting the TfNSW Car Park API](#connecting-the-tfnsw-car-park-api) below) for more, follow the TfNSW User Guide to creating and accessing APIs: https://opendata.transport.nsw.gov.au/developers/userguide .
3. Select the `Parkoala` scheme and run on a simulator or device.

## Connecting the TfNSW Car Park API
The Nearby tab gets live car park availability from Transport for NSW's Car Park API. To connect it:
1. Register for a free account at the [Transport for NSW Open Data Hub](https://opendata.transport.nsw.gov.au) and create an application.
2. Subscribe your application to the **Car Park API** product and copy the API key it gives you.
3. In the repo, copy the template config:
   ```
   cp Config/Secrets.example.xcconfig Secrets.xcconfig
   ```
   (`Secrets.xcconfig` lives at the repo root, next to `Parkoala.xcodeproj`, and is git-ignored so your key is never committed.)
4. Open `Secrets.xcconfig` and paste your key after `TFNSW_API_KEY =`, e.g.:
   ```
   TFNSW_API_KEY = your-key-here
   ```
5. In Xcode, select `Secrets.xcconfig` in the navigator and make sure **Target Membership** includes the `Parkoala` app target (File Inspector, right-hand pane). The app reads the key out of this file as a bundled resource at runtime, so it needs to be bundled with the app.
6. Build and run. If the key is missing or invalid, the app degrades gracefully, nearby car park results will simply empty instead of crashing


