# Project Context

This repo is a barebones Godot 4 project with a Swift GDExtension built through SwiftGodot.

## Verified Local Setup

- Godot: 4.6.1 stable worked when opening `GodotProject/`.
- Swift: 6.3.1 was used to run `make`.
- The Swift package declares `// swift-tools-version: 5.9`.

## Important Fixes

- `SwiftExtension/Package.swift` intentionally lists only `.macOS(.v14)` in `platforms`.
- Do not re-add `.iOS(.v18)` unless the package tools version is raised to a PackageDescription version that supports it. With Swift tools 5.9, `.iOS(.v18)` makes `swift build` fail while evaluating the manifest.
- `GodotProject/project.godot` records Godot 4.6 metadata after the project was opened successfully in Godot 4.6.1.

## Build Notes

Run from the repo root:

```bash
make
```

The build compiles the Swift package and copies these runtime artifacts into `GodotProject/bin/`:

```text
libMyExtension.dylib
libSwiftGodot.dylib
```

Godot loads `MyExtension.gdextension`, which points at `res://bin/libMyExtension.dylib` and uses the exported `swift_entry_point` symbol.
`GodotProject/.godot/extension_list.cfg` is intentionally tracked because Godot uses it to load the GDExtension from a clean checkout. Other `.godot` editor/cache files remain ignored.

Run `make toolchain` to confirm which Swift CLI the Makefile uses. `SWIFT_BIN` prefers the `swift-latest` user toolchain symlink or Swiftly before falling back to `swift`, which keeps Xcode external builds from accidentally using Xcode's default toolchain.

## Xcode Notes

- Open `MyExtension.xcodeproj` for the Godot run/debug workflow.
- Use the shared `MyExtension-Godot` scheme.
- `Cmd-B` runs the external build target, which calls `make debug verify`.
- `Cmd-R` builds the external target, prepares a debug-signed Godot copy under `GodotProject/.debug/Godot.app`, then launches that copy through Xcode's LLDB launcher.
- The external target intentionally sets `passBuildSettingsInEnvironment = 0`; letting Xcode inject its build environment into SwiftPM can break SwiftGodot generated builds.
- The Makefile remains the source of truth for the Swift CLI through `SWIFT_BIN`.
- The checked-in shared scheme uses a `__PROJECT_ROOT__` placeholder. `scripts/create_project.sh` replaces it with the generated repo's absolute path because Xcode's LLDB launcher does not reliably expand `$(PROJECT_DIR)` in the executable path field.
- The debug Godot copy is ignored by Git and signed with `godot-debug.entitlements` because the notarized `/Applications/Godot.app` build denies debugger attach.

## Template Notes

- Use `scripts/create_project.sh` to generate a renamed project from this template.
- The script accepts `--name`, `--template`, and `--dest`, and updates the Swift package, source folder, GDExtension file, dylib references, and Godot project name.
- The script recreates minimal `.godot` extension-load files for the generated project while leaving noisy editor/cache metadata ignored.
- The script also renames the Xcode project and shared scheme for the generated project, then stamps the generated repo path into the scheme.

## Commit Notes

- Confirm with the user before creating commits.
- Use a short past-tense commit subject.
- Put explanatory details after the subject as bullet points.
- When the user says to push, push the current branch to its current tracking branch.

## Troubleshooting Notes

- If `make` fails before compiling sources with an error about `.iOS(.v18)` being unavailable, check that `SwiftExtension/Package.swift` still targets only macOS or raise the Swift tools version intentionally.
- If Godot says it cannot get class `SpinningCube`, run `make verify` and confirm `GodotProject/.godot/extension_list.cfg` points at the project `.gdextension`, then reopen or reload the Godot project.
- A first SwiftGodot build can take a while because it builds SwiftSyntax, SwiftGodot's generator plugins, and the generated Godot bindings.
