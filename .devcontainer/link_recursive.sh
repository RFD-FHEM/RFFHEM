#!/bin/bash
set -uo pipefail

SRC="${PWD}"
declare -r FHEM_DIR="/opt/fhem"

# Whitelist – nur diese Hauptordner werden verarbeitet
WHITELIST=("t" "FHEM" "lib")

# Als-ob-Modus aktivieren (Standard: false, kann mit "--dry-run" aktiviert werden)
DRY_RUN=false
if [[ "${1:-}" == "--dry-run" ]]; then
    DRY_RUN=true
    echo "Running in DRY RUN mode. No changes will be made."
fi

# Resolve a path to its physical location. Works for paths that do not exist yet
# and, crucially, follows symlinked parent directories.
resolve_path() {
    readlink -m -- "$1"
}

# A target may resolve back into the source tree when one of its parent
# directories is a symlink into $SRC (for example /opt/fhem/t -> $SRC/t).
# Writing there would replace the repository's own file with a link to itself,
# destroying the file. Never touch such a target.
points_at_source() {
    local item="$1" target="$2"
    [[ "$(resolve_path "$target")" == "$(resolve_path "$item")" ]]
}

link_file() {
    local item="$1" target="$2"

    if [[ -L "$target" && "$(readlink -- "$target")" == "$item" ]]; then
        return  # already linked, nothing to do
    fi

    if points_at_source "$item" "$target"; then
        echo "Skipping (target resolves to the source file itself): $item"
        return
    fi

    if [[ "$DRY_RUN" == true ]]; then
        echo "[DRY RUN] Would create file link: $target -> $item"
        return
    fi

    rm -f -- "$target"
    ln -s "$item" "$target"
    echo "Created file link: $target -> $item"
}

# Directories are always materialised as real directories, never as symlinks.
# Linking a whole directory hides whatever FHEM ships underneath it – that is how
# /opt/fhem/lib once shadowed the complete FHEM core library and broke every
# module test with "Can't locate FHEM/Core/Utils/Math.pm".
make_directory() {
    local item="$1" target="$2"

    if [[ -d "$target" && ! -L "$target" ]]; then
        return
    fi

    if points_at_source "$item" "$target"; then
        echo "Skipping (target resolves to the source directory itself): $item"
        return
    fi

    if [[ "$DRY_RUN" == true ]]; then
        echo "[DRY RUN] Would create directory: $target"
        return
    fi

    # A stale symlink standing in for the directory has to go first.
    [[ -L "$target" ]] && rm -f -- "$target"
    mkdir -p -- "$target"
    echo "Created directory: $target"
}

for pattern in "${WHITELIST[@]}"; do
    [[ -d "$SRC/$pattern" ]] || continue

    while IFS= read -r -d '' item; do
        rel_path="${item#"$SRC"/}"
        target="$FHEM_DIR/$rel_path"

        if [[ -d "$item" ]]; then
            make_directory "$item" "$target"
        else
            link_file "$item" "$target"
        fi
    done < <(find "$SRC/$pattern" -mindepth 1 -print0 2>/dev/null | sort -z)
done
