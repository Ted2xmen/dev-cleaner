# dev-cleaner

A macOS disk cleanup script for developers. Clears caches, build artifacts, and unused data from common development tools — safely skipping anything that isn't installed.

## Why?

Developer tools accumulate gigabytes of cached data over time: Xcode DerivedData, Docker images, npm/yarn/pnpm caches, Gradle builds, and more. When your Mac runs low on disk space, this script reclaims it all in one run.

## What it cleans

| Category | What gets cleaned |
|---|---|
| **macOS** | Application logs, Trash |
| **Xcode** | DerivedData, Archives, iOS DeviceSupport, simulators |
| **Homebrew** | Old downloads, unused dependencies |
| **Docker** | Unused images, containers, volumes |
| **Node.js** | npm, yarn, pnpm caches |
| **Python** | pip / pip3 cache |
| **Ruby** | Old gem versions |
| **Go** | Build cache, module cache |
| **Rust** | Cargo registry cache |
| **Gradle** | Build caches |
| **Maven** | Local repository |
| **CocoaPods** | Pod cache |
| **React Native** | Metro bundler cache, Android cache |
| **Apps** | Spotify, Google Chrome caches |
| **npkill** | Interactive `node_modules` scanner (optional) |

## Usage

```bash
git clone https://github.com/ted2xmen/dev-cleaner.git
cd dev-cleaner
chmod +x clean.sh
bash clean.sh
```

Or run it directly:

```bash
curl -fsSL https://raw.githubusercontent.com/ted2xmen/dev-cleaner/main/clean.sh | bash
```

## Safety

- Each section checks if the tool is installed before running (`command -v`)
- Directory-based cleanups check if the directory exists first
- All commands suppress errors gracefully — nothing breaks if a tool is missing
- `npkill` runs last and only if you opt in (interactive prompt)
- The script shows disk space before and after so you can see exactly how much was freed

## Requirements

- macOS
- Bash

Everything else is optional. The script adapts to whatever you have installed.

## License

MIT
