# Template Usage

Use this repo as a starting point for a new Godot 4 project with a Swift GDExtension powered by SwiftGodot.

## Platform Scope

This template is verified for macOS development with Godot 4.6.

SwiftGodot currently describes support for macOS, iOS, Linux, and Windows, but this repo only includes the macOS build path out of the box:

- macOS: verified. `make` builds `.dylib` files and copies them into `GodotProject/bin/`.
- iOS: expected to be possible with SwiftGodot, but this template does not include an iOS build/export pipeline.
- Linux: expected to be possible with SwiftGodot, but you must build Linux `.so` libraries and package them for Godot.
- Windows: expected to be possible with SwiftGodot, but you must build Windows `.dll` files and include the required Swift runtime DLLs.

Do not assume this template can target every platform Godot can export to. Each target platform needs native Swift build support, matching GDExtension library entries, and runtime packaging.

## Create a New Project Copy

The easiest path is to use the included scaffold script:

```bash
scripts/create_project.sh --name MySwiftProject --dest ../MySwiftProject
```

The script can also use an explicit local template path or git URL:

```bash
scripts/create_project.sh \
  --template /path/to/swift-godot \
  --name MySwiftProject \
  --dest /path/to/MySwiftProject
```

It will copy or clone the template, remove generated build/editor artifacts, and rename the Swift package, source folder, GDExtension file, dylib references, and Godot project name.
The `scripts/` folder is intentionally copied too, so a generated project can be used as a template for another project later.

After scaffolding, you can initialize a fresh git repo from the top-level generated folder:

```bash
cd /path/to/MySwiftProject
git init
git add .
git commit
```

Run git commands from the generated repo root, not from `GodotProject/`.

You can also do the copy manually. From a parent folder where you want the new project to live:

```bash
cp -R /path/to/swift-godot MyNewProject
cd MyNewProject
```

If you copied the `.git` directory and want a fresh repo history:

```bash
rm -rf .git
git init
```

## Rename the Project

The template uses `MyExtension` for the Swift extension and `MyFirstGame` for the Godot project name. Rename these deliberately so SwiftPM, the generated dylib, and Godot's `.gdextension` file stay in agreement.

### Swift Package

Edit `SwiftExtension/Package.swift`:

- Change `name: "MyExtension"` to your Swift package name.
- Change `.library(name: "MyExtension", type: .dynamic, targets: ["MyExtension"])`.
- Change the target name from `"MyExtension"` if you want the Swift module to use a new name.

If you rename the target, also rename this folder:

```text
SwiftExtension/Sources/MyExtension/
```

### Swift Source

Edit the Swift files under `SwiftExtension/Sources/<TargetName>/`.

The exported entry point is currently:

```swift
#initSwiftExtension(cdecl: "swift_entry_point", types: [SpinningCube.self])
```

You can keep `swift_entry_point` as-is. If you change it, update `GodotProject/MyExtension.gdextension` to use the same `entry_symbol`.

Register every custom SwiftGodot type in the `types:` array.

### Build File

Edit `Makefile`:

- Update `LIB_NAME` if you use it later for scripts or cleanup.
- Update copy paths if you change the Swift package directory, Godot project directory, or output library name.

The dynamic library name comes from the SwiftPM product name. For a product named `MyGameExtension`, SwiftPM builds:

```text
libMyGameExtension.dylib
```

### Godot GDExtension File

Rename `GodotProject/MyExtension.gdextension` if desired, then edit it:

```ini
[configuration]
entry_symbol = "swift_entry_point"
compatibility_minimum = 4.2

[libraries]
macos.debug = "res://bin/libMyExtension.dylib"
macos.release = "res://bin/libMyExtension.dylib"
```

Update the macOS library paths to match the SwiftPM product name you chose.

For example, if your SwiftPM product is `MyGameExtension`:

```ini
macos.debug = "res://bin/libMyGameExtension.dylib"
macos.release = "res://bin/libMyGameExtension.dylib"
```

### Godot Project Name

Edit `GodotProject/project.godot`:

```ini
config/name="MyFirstGame"
```

Change it to the name you want Godot to show in the project manager and window title.

## Keep These Settings Unless You Know Why

- Keep `SwiftExtension/Package.swift` on `.macOS(.v14)` unless you are intentionally adding platform support.
- Do not add `.iOS(.v18)` while the package declares `// swift-tools-version: 5.9`; that combination prevents SwiftPM from evaluating the manifest.
- Keep `swift_entry_point` unless you update both Swift source and the `.gdextension` file together.
- Keep `libSwiftGodot.dylib` in `GodotProject/bin/`; `libMyExtension.dylib` depends on it at runtime.

## First Run Checklist

From the repo root:

```bash
make
```

Build output is quiet by default. Use this if you want the full SwiftPM output:

```bash
make VERBOSE=1
```

The first build can still take a while because SwiftPM compiles SwiftGodot, SwiftSyntax, macros, and generated Godot bindings. The scaffold script intentionally does not copy `.build` into new projects; SwiftPM will reuse its normal dependency caches where it safely can.
Run `make toolchain` to see which Swift CLI the Makefile uses. Override it with `SWIFT_BIN=/path/to/swift` if your Xcode workflow needs a specific toolchain.

Confirm the Godot bin folder contains:

```text
GodotProject/bin/lib<YourExtensionName>.dylib
GodotProject/bin/libSwiftGodot.dylib
```

Then run:

```bash
make verify
```

`make verify` checks that the copied extension dylib exists, `libSwiftGodot.dylib` exists, the `.gdextension` file points to the expected macOS dylib, and the Swift package product name matches the GDExtension library name.
It also checks `GodotProject/.godot/extension_list.cfg`, which is intentionally kept minimal so Godot loads the GDExtension from a fresh scaffold. Other `.godot` editor/cache files remain ignored.

`make doctor` is also available as an alias for `make verify`.

Generated projects also include an Xcode project:

```text
<ProjectName>.xcodeproj
```

Open it in Xcode and select the shared `<ProjectName>-Godot` scheme:

- **Cmd-B** runs `make debug verify`.
- **Cmd-R** runs `make prepare-godot-debug` and launches `GodotProject/` through Xcode's LLDB launcher.

`make prepare-godot-debug` copies `/Applications/Godot.app` into `GodotProject/.debug/Godot.app` and signs that copy with `godot-debug.entitlements`, leaving the normal installed Godot app untouched. `GodotProject/.debug/` is ignored by Git.

The scaffold script writes the generated repo's absolute path into the shared scheme. Xcode's LLDB launcher does not reliably expand `$(PROJECT_DIR)` in the executable path field, so regenerate the project or edit the scheme if you move the generated folder.

Open `GodotProject/` in Godot.

On macOS, you can also run this from the generated repo root:

```bash
make open
```

If Godot is installed somewhere else:

```bash
make open GODOT_BIN=/path/to/Godot
```

For command-line debugging, generated projects also include LLDB helpers:

```bash
make debug-run     # launch Godot under LLDB
make debug-attach  # attach LLDB to an already-running Godot process
```

Use either `make debug-run` or `make debug-attach`, not both. `debug-run` launches Godot under LLDB from the start; `debug-attach` attaches to a Godot process you already started.

These targets use terminal LLDB rather than Xcode's GUI debugger. Breakpoints set in Xcode do not automatically carry over to terminal LLDB. For Xcode breakpoints, attach from Xcode with **Debug > Attach to Process by PID or Name...**.

Confirm:

- The project opens without GDExtension load errors.
- Your custom Swift node type appears in the Add Child Node dialog.
- The main scene runs.

To remove only copied dylibs from `GodotProject/bin/` while preserving SwiftPM's `.build` cache:

```bash
make clean-bin
```

## Prompt for Future AI Assistant Chats

You can ask an AI coding assistant to create a new project from this template with a prompt like:

```text
Use /Users/jacobhawken/code/gamedev/SwiftGodot/swift-godot as the template for a new SwiftGodot project named <ProjectName> in <new absolute folder>. Run scripts/create_project.sh with that template path, project name, and destination. Then run make in the generated project and verify the Godot extension loads.
```

Replace `<new absolute folder>` and `<ProjectName>` with the real destination and name.

## Troubleshooting

See `PROJECT_CONTEXT.md` for the setup decisions and issues already discovered while getting this template running.
