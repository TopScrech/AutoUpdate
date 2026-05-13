# AutoUpdate

Modern async/await macOS app updater library inspired by `mxcl/AppUpdater`, powered by GitHub Releases
<br><br>
<img width="504" height="494" alt="Screenshot 2026-05-09 at 19 17 00" src="https://github.com/user-attachments/assets/5dfc0697-a0aa-49c0-9d30-03274d4feeb8" />

## Features

- Swift 6 concurrency-first API
- GitHub Releases provider out of the box
- Semantic version comparison with prerelease support
- Asset matching compatible with the classic naming format
  - `repo-1.2.3.zip`
  - `repo-1.2.3.tar.gz`
  - `repo-v1.2.3.zip`
- Optional daily background checks via `NSBackgroundActivityScheduler`
- Code-sign identity verification before install
- Install-and-relaunch flow for in-place updates

### Hierarchy
- v1.0-patch.1
- v1.0
- v1.0-rc.1
- v1.0-beta.1
- v1.0-alpha.1

## Installation

```swift
.package(url: "https://github.com/TopScrech/Auto-Update.git", from: "1.0.0")
```

## Quick start

```swift
import AutoUpdate

let updater = AppUpdater(
    owner: "your-github-owner",
    repository: "your-repo",
    allowPrereleases: false
)

Task {
    switch try await updater.prepareUpdateIfAvailable() {
    case .upToDate:
        break
        
    case .prepared(let preparedUpdate):
        try await updater.installAndRelaunch(preparedUpdate)
    }
}
```

## GitHub proxy

If you use a GitHub proxy or mirror that expects the original GitHub URL to be appended after a base URL, pass `gitHubProxyURL`

```swift
let updater = AppUpdater(
    owner: "your-github-owner",
    repository: "your-repo",
    gitHubProxyURL: URL(string: "https://ghproxy.example.com"),
    allowPrereleases: false
)
```

This prefixes both the GitHub Releases API request and matching asset downloads, for example `https://ghproxy.example.com/https://api.github.com/...`

## Scheduled checks

```swift
Task {
    await updater.startAutomaticChecks(
        every: 24 * 60 * 60,
        installAfterPreparation: false
    )
}
```

## Projects using AutoUpdate
- 💨 [FanControl](https://github.com/TopScrech/FanControl) - Fan control for macOS
- ☕️ [Latte](https://github.com/TopScrech/Latte) - Keep your Mac awake
