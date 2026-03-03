# AutoUpdate

Modern async/await macOS app updater inspired by `mxcl/AppUpdater`

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

## Install

```swift
.package(url: "https://github.com/your-org/AutoUpdate.git", from: "1.0.0")
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

## Scheduled checks

```swift
Task {
    await updater.startAutomaticChecks(
        every: 24 * 60 * 60,
        installAfterPreparation: false
    )
}
```
