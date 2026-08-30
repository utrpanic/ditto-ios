# Agent Instructions

## Project Commands
- Preferred script commands:
  - `./setup.sh --no-open`
  - `./build.sh -scheme Feature`
- Run `./setup.sh --no-open` only when a session has just started, Swift/source files were added or deleted, or a `Project.swift` file changed.
- Build feature work with `./build.sh -scheme Feature`.
- Build the full app with `./build.sh` when app-level validation is needed.
- Do not invoke `tuist` directly; use the scripts above.

## Architecture
- The project is organized with Tuist into `App`, `Architecture`, `Core`, `Feature`, and `Platform`.
- Feature modules use the RIBsLite shape: `Buildable`, `Builder`, `Interactor`, `Router`, `ViewController`, and state/view files when needed.
- For SwiftUI feature screens, wrap the SwiftUI view in a `UIHostingController` and keep it conforming to the feature controllable protocol.
- Prefer existing feature patterns before introducing new abstractions. `TopPodcasts` is the reference for a data-loading SwiftUI feature.

## Repository Layer
- Repository interfaces live under `Core/Repository/Interface`.
- Repository implementations live under `Core/Repository/Implementation`.
- Feature dependencies should depend on repository interfaces, not concrete implementations.

## Working Rules
- Keep changes scoped to the requested feature or layer.
- Use `rg` for code search.
- Preserve user changes in the working tree.
