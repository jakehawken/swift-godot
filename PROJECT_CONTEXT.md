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

## Template Notes

- Use `scripts/create_project.sh` to generate a renamed project from this template.
- The script accepts `--name`, `--template`, and `--dest`, and updates the Swift package, source folder, GDExtension file, dylib references, and Godot project name.
- The script recreates minimal `.godot` extension-load files for the generated project while leaving noisy editor/cache metadata ignored.

## Commit Notes

- Confirm with the user before creating commits.
- Use a short past-tense commit subject.
- Put explanatory details after the subject as bullet points.
- When the user says to push, push the current branch to its current tracking branch.

## Troubleshooting Notes

- If `make` fails before compiling sources with an error about `.iOS(.v18)` being unavailable, check that `SwiftExtension/Package.swift` still targets only macOS or raise the Swift tools version intentionally.
- If Godot says it cannot get class `SpinningCube`, run `make verify` and confirm `GodotProject/.godot/extension_list.cfg` points at the project `.gdextension`, then reopen or reload the Godot project.
- A first SwiftGodot build can take a while because it builds SwiftSyntax, SwiftGodot's generator plugins, and the generated Godot bindings.
