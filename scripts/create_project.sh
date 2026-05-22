#!/usr/bin/env bash
set -euo pipefail

usage() {
    cat <<'EOF'
Create a new SwiftGodot project from this template.

Usage:
  scripts/create_project.sh --name MySwiftProject [--template <path-or-git-url>] [--dest <folder>]

Options:
  --name      Swift package, extension, and Godot project name. Must be a valid Swift identifier.
  --template  Local template path or git URL. Defaults to this script's repo.
  --dest      Destination folder. Defaults to ./<name>.

Examples:
  scripts/create_project.sh --name MySwiftProject --dest ../MySwiftProject
  scripts/create_project.sh --template https://github.com/example/swift-godot.git --name MySwiftProject
EOF
}

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
default_template="$(cd "$script_dir/.." && pwd)"

project_name=""
template_source="$default_template"
destination=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --name)
            project_name="${2:-}"
            shift 2
            ;;
        --template)
            template_source="${2:-}"
            shift 2
            ;;
        --dest)
            destination="${2:-}"
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Unknown argument: $1" >&2
            usage >&2
            exit 1
            ;;
    esac
done

if [[ -z "$project_name" ]]; then
    echo "Missing required --name." >&2
    usage >&2
    exit 1
fi

if [[ ! "$project_name" =~ ^[A-Za-z][A-Za-z0-9_]*$ ]]; then
    echo "Project name must be a valid Swift identifier: start with a letter and use only letters, numbers, and underscores." >&2
    exit 1
fi

if [[ -z "$destination" ]]; then
    destination="$PWD/$project_name"
fi

if [[ -e "$destination" ]]; then
    echo "Destination already exists: $destination" >&2
    exit 1
fi

is_git_url=false
case "$template_source" in
    http://*|https://*|ssh://*|git@*:*)
        is_git_url=true
        ;;
esac

if [[ "$is_git_url" == true ]]; then
    git clone "$template_source" "$destination"
else
    if [[ ! -d "$template_source" ]]; then
        echo "Template path does not exist or is not a directory: $template_source" >&2
        exit 1
    fi

    mkdir -p "$destination"
    if command -v rsync >/dev/null 2>&1; then
        rsync -a \
            --exclude '.git/' \
            --exclude 'SwiftExtension/.build/' \
            --exclude 'GodotProject/.godot/' \
            --exclude 'GodotProject/bin/*.dylib' \
            --exclude 'GodotProject/bin/*.so' \
            --exclude 'GodotProject/bin/*.dll' \
            "$template_source/" "$destination/"
    else
        cp -R "$template_source/." "$destination/"
    fi
fi

rm -rf \
    "$destination/.git" \
    "$destination/SwiftExtension/.build" \
    "$destination/GodotProject/.godot"

rm -f \
    "$destination"/GodotProject/bin/*.dylib \
    "$destination"/GodotProject/bin/*.so \
    "$destination"/GodotProject/bin/*.dll

old_source_dir="$destination/SwiftExtension/Sources/MyExtension"
new_source_dir="$destination/SwiftExtension/Sources/$project_name"
if [[ -d "$old_source_dir" ]]; then
    mv "$old_source_dir" "$new_source_dir"
fi

old_source_file="$new_source_dir/MyExtension.swift"
new_source_file="$new_source_dir/$project_name.swift"
if [[ -f "$old_source_file" ]]; then
    mv "$old_source_file" "$new_source_file"
fi

old_gdextension="$destination/GodotProject/MyExtension.gdextension"
new_gdextension="$destination/GodotProject/$project_name.gdextension"
if [[ -f "$old_gdextension" ]]; then
    mv "$old_gdextension" "$new_gdextension"
fi

old_gdextension_uid="$destination/GodotProject/MyExtension.gdextension.uid"
new_gdextension_uid="$destination/GodotProject/$project_name.gdextension.uid"
if [[ -f "$old_gdextension_uid" ]]; then
    mv "$old_gdextension_uid" "$new_gdextension_uid"
fi

mkdir -p "$destination/GodotProject/.godot"
touch "$destination/GodotProject/.godot/.gdignore"
printf 'res://%s.gdextension\n' "$project_name" > "$destination/GodotProject/.godot/extension_list.cfg"

replace_files=(
    "$destination/README.md"
    "$destination/PROJECT_CONTEXT.md"
    "$destination/TEMPLATE_USAGE.md"
    "$destination/Makefile"
    "$destination/GodotProject/project.godot"
    "$new_gdextension"
    "$new_source_file"
    "$destination/SwiftExtension/Package.swift"
)

for file in "${replace_files[@]}"; do
    if [[ -f "$file" ]]; then
        perl -0pi -e "s/godot-swift/$project_name/g; s/MyFirstGame/$project_name/g; s/MyExtension/$project_name/g; s/libMyExtension/lib$project_name/g" "$file"
    fi
done

cat <<EOF
Created SwiftGodot project:
  $destination

Next steps:
  cd "$destination"
  make
  open GodotProject/ in Godot
EOF
