SWIFT_PKG_DIR   := SwiftExtension
GODOT_BIN_DIR   := GodotProject/bin
LIB_NAME        := libMyExtension
EXTENSION_NAME  := $(patsubst lib%,%,$(LIB_NAME))
GDEXTENSION     := GodotProject/$(EXTENSION_NAME).gdextension
EXTENSION_LIST  := GodotProject/.godot/extension_list.cfg
GODOT_BIN       ?= /Applications/Godot.app/Contents/MacOS/Godot
GODOT_PROCESS   ?= Godot
LLDB            ?= lldb

ifeq ($(VERBOSE),1)
SWIFT_BUILD_FLAGS :=
Q :=
else
SWIFT_BUILD_FLAGS := --quiet
Q := @
endif

.PHONY: all debug release verify doctor status open debug-run debug-attach clean-bin clean

# Default: debug build
all: debug

debug:
	@echo "Building debug Swift extension..."
	$(Q)cd $(SWIFT_PKG_DIR) && swift build $(SWIFT_BUILD_FLAGS)
	@$(MAKE) copy-libs CONFIG=debug

release:
	@echo "Building release Swift extension..."
	$(Q)cd $(SWIFT_PKG_DIR) && swift build -c release $(SWIFT_BUILD_FLAGS)
	@$(MAKE) copy-libs CONFIG=release

.PHONY: copy-libs
copy-libs:
	@mkdir -p $(GODOT_BIN_DIR)
	@test -f "$(SWIFT_PKG_DIR)/.build/$(CONFIG)/$(LIB_NAME).dylib" || \
		(echo "Missing expected extension dylib: $(SWIFT_PKG_DIR)/.build/$(CONFIG)/$(LIB_NAME).dylib" >&2; \
		 echo "Run 'make VERBOSE=1' to see the full Swift build output." >&2; exit 1)
	@test -f "$(SWIFT_PKG_DIR)/.build/$(CONFIG)/libSwiftGodot.dylib" || \
		(echo "Missing SwiftGodot runtime dylib: $(SWIFT_PKG_DIR)/.build/$(CONFIG)/libSwiftGodot.dylib" >&2; \
		 echo "Run 'make VERBOSE=1' to see the full Swift build output." >&2; exit 1)
	$(Q)cp "$(SWIFT_PKG_DIR)/.build/$(CONFIG)/$(LIB_NAME).dylib" "$(GODOT_BIN_DIR)/"
	$(Q)cp "$(SWIFT_PKG_DIR)/.build/$(CONFIG)/libSwiftGodot.dylib" "$(GODOT_BIN_DIR)/"
	@echo "Copied $(LIB_NAME).dylib and libSwiftGodot.dylib to $(GODOT_BIN_DIR)."

verify:
	@test -f "$(GODOT_BIN_DIR)/$(LIB_NAME).dylib" || \
		(echo "Missing copied extension dylib: $(GODOT_BIN_DIR)/$(LIB_NAME).dylib" >&2; exit 1)
	@test -f "$(GODOT_BIN_DIR)/libSwiftGodot.dylib" || \
		(echo "Missing copied SwiftGodot runtime dylib: $(GODOT_BIN_DIR)/libSwiftGodot.dylib" >&2; exit 1)
	@test -f "$(GDEXTENSION)" || \
		(echo "Missing GDExtension file: $(GDEXTENSION)" >&2; exit 1)
	@test -f "$(EXTENSION_LIST)" || \
		(echo "Missing Godot extension list: $(EXTENSION_LIST)" >&2; \
		 echo "Create it with: echo 'res://$(EXTENSION_NAME).gdextension' > $(EXTENSION_LIST)" >&2; exit 1)
	@grep -qx 'res://$(EXTENSION_NAME).gdextension' "$(EXTENSION_LIST)" || \
		(echo "$(EXTENSION_LIST) must contain res://$(EXTENSION_NAME).gdextension" >&2; exit 1)
	@grep -q 'macos.debug = "res://bin/$(LIB_NAME).dylib"' "$(GDEXTENSION)" || \
		(echo "$(GDEXTENSION) does not point macos.debug at res://bin/$(LIB_NAME).dylib" >&2; exit 1)
	@grep -q 'macos.release = "res://bin/$(LIB_NAME).dylib"' "$(GDEXTENSION)" || \
		(echo "$(GDEXTENSION) does not point macos.release at res://bin/$(LIB_NAME).dylib" >&2; exit 1)
	@product_name=$$(perl -ne 'if (/\.library\(name:\s*"([^"]+)"/) { print $$1; exit }' "$(SWIFT_PKG_DIR)/Package.swift"); \
		if [ "$$product_name" != "$(EXTENSION_NAME)" ]; then \
			echo "Swift package product '$$product_name' does not match GDExtension library '$(EXTENSION_NAME)'." >&2; \
			exit 1; \
		fi
	@echo "Verified $(EXTENSION_NAME): dylibs are copied and SwiftPM/GDExtension names match."
	@$(MAKE) --no-print-directory status

doctor: verify

status:
	@echo "Repo root: $$(pwd)"
	@echo "Godot project folder: $$(pwd)/GodotProject"

open:
	@test -x "$(GODOT_BIN)" || \
		(echo "Godot executable not found: $(GODOT_BIN)" >&2; \
		 echo "Set GODOT_BIN=/path/to/Godot when running make open." >&2; exit 1)
	"$(GODOT_BIN)" --path GodotProject

debug-run: debug verify
	@test -x "$(GODOT_BIN)" || \
		(echo "Godot executable not found: $(GODOT_BIN)" >&2; \
		 echo "Set GODOT_BIN=/path/to/Godot when running make debug-run." >&2; exit 1)
	@echo "Launching Godot under LLDB. Type 'run' at the LLDB prompt to start."
	$(LLDB) -- "$(GODOT_BIN)" --path GodotProject

debug-attach: debug verify
	@echo "Attaching LLDB to process named $(GODOT_PROCESS). Start the project in Godot first if it is not already running."
	$(LLDB) -n "$(GODOT_PROCESS)"

clean-bin:
	$(Q)rm -f "$(GODOT_BIN_DIR)/$(LIB_NAME).dylib" "$(GODOT_BIN_DIR)/libSwiftGodot.dylib"
	@echo "Removed copied dylibs from $(GODOT_BIN_DIR)."

clean:
	$(Q)cd $(SWIFT_PKG_DIR) && swift package clean
	@$(MAKE) clean-bin
