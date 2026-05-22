# godot-swift

A barebones Godot 4 project with a Swift GDExtension, powered by [SwiftGodot](https://github.com/migueldeicaza/SwiftGodot).

## Repo root vs Godot project folder

Run `make` commands from this repo root, where the `Makefile` lives. Open `GodotProject/` in Godot; it is the Godot project folder inside the larger SwiftGodot template repo.

## Project layout

```
godot-swift/
├── GodotProject/               # Open this folder in Godot 4
│   ├── project.godot
│   ├── MyExtension.gdextension # Tells Godot where to find the library
│   └── bin/                    # Built .dylib lands here after `make`
└── SwiftExtension/             # Swift Package (your extension code)
    ├── Package.swift
    └── Sources/MyExtension/
        └── MyExtension.swift   # SpinningCube demo node
```

## Requirements

- [Godot 4.6](https://godotengine.org/download/) has been verified with this project. SwiftGodot's upstream README currently describes Godot 4.4 support, so prefer the version recorded in `GodotProject/project.godot` unless you are intentionally testing another Godot release.
- Xcode / Swift toolchain. This repo was verified with Swift 6.3.1, while the extension package itself declares Swift tools 5.9.

## Getting started

### 1. Build the Swift extension

```bash
make          # debug build
# or
make release  # optimised build
```

This compiles the Swift package and copies `libMyExtension.dylib` into `GodotProject/bin/`.
The build also copies SwiftGodot's runtime dylib, `libSwiftGodot.dylib`, which `libMyExtension.dylib` loads at runtime.
Build output is quiet by default; use `make VERBOSE=1` to show the full SwiftPM output.
The first build can still take a while because SwiftPM compiles SwiftGodot, SwiftSyntax, macros, and generated Godot bindings. Generated projects do not copy `.build`; SwiftPM will reuse its normal dependency caches where it safely can.

After building, you can verify that the copied dylibs and GDExtension metadata agree:

```bash
make verify
```

`make verify` also checks `GodotProject/.godot/extension_list.cfg`, which is intentionally kept in the repo so Godot loads `MyExtension.gdextension` from a clean checkout. Other `.godot` editor/cache files remain ignored.

`make doctor` is also available as an alias for `make verify`.

To remove only the copied dylibs from `GodotProject/bin/` without clearing SwiftPM's build cache:

```bash
make clean-bin
```

To open the project with the default macOS Godot app path:

```bash
make open
```

If Godot is installed somewhere else, pass its executable path:

```bash
make open GODOT_BIN=/path/to/Godot
```

### 2. Open the Godot project

Open `GodotProject/` in Godot 4. Godot will automatically load `MyExtension.gdextension` and register the `SpinningCube` node type.

### 3. Use your Swift node

In any 3D scene, add a child node and search for **SpinningCube** — it will appear under **Node3D**. It will create a spinning box at runtime.

## Adding your own Swift nodes

1. Create a new Swift file under `SwiftExtension/Sources/MyExtension/`.
2. Annotate your class with `@Godot` and subclass a Godot base type.
3. Add the new type to the `#initSwiftExtension` call in `MyExtension.swift`.
4. Run `make`, optionally run `make verify`, and restart/reload the Godot editor.

## Rebuilding without restarting Godot

Use **Project > Reload Current Project** in the Godot editor after running `make` to pick up the updated library.

## Debugging in Xcode

Xcode can attach its debugger to a running Godot process so you can set Swift breakpoints in your extension.
The Makefile also includes terminal LLDB helpers if you prefer a command-line debugger.

### One-time setup: re-sign Godot

The official Godot binary is signed without the `com.apple.security.get-task-allow` entitlement, which macOS requires before an external debugger can attach. Re-sign it once with an ad-hoc signature that includes that entitlement:

```bash
# Clear any Gatekeeper quarantine flags first
xattr -cr /Applications/Godot.app

# Re-sign with the debug entitlement
codesign \
  --sign - \
  --entitlements godot-debug.entitlements \
  --force \
  --deep \
  /Applications/Godot.app
```

The `godot-debug.entitlements` file in the repo root contains the required entitlement. You will need to repeat this step after every Godot update.

### Fix "Cannot find X in scope" errors in Xcode

Xcode's indexer needs to build the package itself before it can resolve SwiftGodot types:

1. Open the Swift package in Xcode: `xed SwiftExtension`
2. Build with **⌘B**.
3. Open the **Issue Navigator** (**⌘5**). At the bottom you will see a prompt to **Trust & Enable** the SwiftGodot macro/plugin. Click it — Xcode may ask you to do this **twice** (once for each plugin SwiftGodot ships).
4. Once all libraries are trusted and enabled, Xcode will complete the build and all "Cannot find X in scope" errors will disappear.

### Attaching to a running game

1. Run `make` to build the debug `.dylib`.
2. Open `GodotProject/` in Godot and press **Run** (F5).
3. In Xcode, open the Swift package: `xed SwiftExtension`
4. Set any breakpoints you want in your Swift source files.
5. In the menu bar choose **Debug › Attach to Process by PID or Name…**, type `Godot`, and click **Attach**.

Xcode will attach to the Godot process and stop at your Swift breakpoints.

### Debugging with LLDB from Make

For command-line debugging, you can launch Godot under LLDB:

```bash
make debug-run
```

At the LLDB prompt, type:

```text
run
```

Or attach LLDB to an already-running Godot process:

```bash
make debug-attach
```

Use either `make debug-run` or `make debug-attach`, not both. `debug-run` launches Godot under LLDB from the start; `debug-attach` attaches to a Godot process you already started.

`make debug-attach` builds first, verifies the copied dylibs, and then runs `lldb -n Godot`. If your Godot process uses a different name, pass it with `GODOT_PROCESS`:

```bash
make debug-attach GODOT_PROCESS=Godot
```

These targets use terminal LLDB, not Xcode's GUI debugger. Breakpoints set in Xcode do not automatically carry over to terminal LLDB. To use Xcode breakpoints in Xcode, use **Debug > Attach to Process by PID or Name...** as described above.

## Project notes

See [PROJECT_CONTEXT.md](PROJECT_CONTEXT.md) for the current debugging notes, known setup decisions, and fixes discovered while getting this project running.
See [TEMPLATE_USAGE.md](TEMPLATE_USAGE.md) for instructions on using this repo as a starter for a new SwiftGodot project.
