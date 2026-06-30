#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="${MODULE_REPO_ROOT:-/workspace/RFFHEM}"
if [[ ! -d "${SRC}" ]]; then
    SRC="$(cd "${SCRIPT_DIR}/.." && pwd)"
fi
declare -r FHEM_DIR="/opt/fhem"

# Whitelist – nur diese Hauptordner werden verarbeitet
WHITELIST=("t" "FHEM" "lib" ".devcontainer/config")

# Als-ob-Modus aktivieren (Standard: false, kann mit "--dry-run" aktiviert werden)
DRY_RUN=false
if [[ "${1:-}" == "--dry-run" ]]; then
    DRY_RUN=true
    echo "Running in DRY RUN mode. No changes will be made."
fi

# Array für "virtuell verlinkte" Verzeichnisse
declare -a LINKED_DIRS=()

# Prüft, ob ein Pfad zur Whitelist gehört
is_whitelisted() {
    local path="$1"
    for pattern in "${WHITELIST[@]}"; do
        if [[ "$path" == "$pattern" || "$path" == "$pattern/"* ]]; then
            return 0  # in Whitelist
        fi
    done
    return 1  # nicht in Whitelist
}

# Prüft, ob ein Pfad unter einem bereits "virtuell verlinkten" Ordner liegt
is_under_linked() {
    local rel_path="$1"
    for ld in "${LINKED_DIRS[@]}"; do
        if [[ "$rel_path" == "$ld" || "$rel_path" == "$ld/"* ]]; then
            return 0
        fi
    done
    return 1
}

# Für jedes Muster der Whitelist suchen wir rekursiv.
# Das Top-Level-Verzeichnis selbst muss ebenfalls verarbeitet werden, damit
# seine Kinder nicht auf einen noch nicht existierenden Zielpfad zeigen.
for pattern in "${WHITELIST[@]}"; do
    find "$SRC/$pattern" -mindepth 0 -print0 2>/dev/null | sort -z | while IFS= read -r -d '' item; do
        rel_path="${item#$SRC/}"
        target="$FHEM_DIR/$rel_path"

        if ! is_whitelisted "$rel_path"; then
            echo "Skipping (not in whitelist): $item"
            continue
        fi

        # Prüfen, ob der Ordner bereits "virtuell verlinkt" wurde
        if is_under_linked "$rel_path"; then
            echo "Skipping (parent directory already virtually linked): $item"
            continue
        fi

        if [[ "$rel_path" == "FHEM" && -d "$item" ]]; then
            # Preserve the base-image FHEM directory so bundled helper modules
            # like FHEM/Meta.pm and RTypes.pm remain available. The workspace
            # files below FHEM are linked individually into that directory.
            if [[ -e "$target" || -L "$target" ]]; then
                if [[ "$DRY_RUN" == true ]]; then
                    echo "[DRY RUN] Would replace existing runtime directory: $target"
                else
                    rm -rf "$target"
                    echo "Removed existing runtime directory: $target"
                fi
            fi

            if [[ "$DRY_RUN" == true ]]; then
                echo "[DRY RUN] Would create runtime directory: $target"
            else
                mkdir -p "$target"
                echo "Created runtime directory: $target"
            fi
            continue
        fi

        if [[ -d "$item" ]]; then
            # Falls es sich um einen Ordner handelt
            if [[ -e "$target" || -L "$target" ]]; then
                if [[ "$DRY_RUN" == true ]]; then
                    echo "[DRY RUN] Would replace existing directory: $target"
                else
                    rm -rf "$target"
                    echo "Removed existing directory: $target"
                fi
            fi

            if [[ "$DRY_RUN" == true ]]; then
                echo "[DRY RUN] Would ensure directory parent exists: $(dirname "$target")"
            else
                mkdir -p "$(dirname "$target")"
            fi

            if [[ "$DRY_RUN" == true ]]; then
                echo "[DRY RUN] Would create directory link: $target -> $item"
            else
                ln -s "$item" "$target"
                echo "Created directory link: $target -> $item"
            fi
            # Speichere diesen Ordner als "virtuell verlinkt"
            LINKED_DIRS+=("$rel_path")
        else
            # Falls eine Datei verarbeitet wird, prüfen, ob ihr Elternverzeichnis schon "virtuell verlinkt" ist
            parent_dir=$(dirname "$rel_path")
            if is_under_linked "$parent_dir"; then
                echo "Skipping (parent directory already virtually linked): $item"
                continue
            fi

            # Prüfen, ob die Datei im Ziel existiert
            if [[ -f "$target" || -L "$target" ]]; then
                if [[ "$DRY_RUN" == true ]]; then
                    echo "[DRY RUN] Would replace existing file: $target"
                else
                    rm -f "$target"
                    echo "Removed existing file: $target"
                fi
            fi

            if [[ "$DRY_RUN" == true ]]; then
                echo "[DRY RUN] Would ensure file parent exists: $(dirname "$target")"
            else
                mkdir -p "$(dirname "$target")"
            fi

            # Erstellen des Links
            if [[ ! -e "$target" ]]; then
                if [[ "$DRY_RUN" == true ]]; then
                    echo "[DRY RUN] Would create file link: $target -> $item"
                else
                    ln -s "$item" "$target"
                    echo "Created file link: $target -> $item"
                fi
            fi
        fi
    done
done

# Restore core helper modules from the image's base installation.
# The workspace overlay intentionally does not own these files.
for helper in Meta.pm RTypes.pm; do
    src="/usr/src/fhem/FHEM/${helper}"
    target="${FHEM_DIR}/FHEM/${helper}"

    if [[ ! -e "$src" ]]; then
        continue
    fi

    if [[ -e "$target" || -L "$target" ]]; then
        if [[ "$DRY_RUN" == true ]]; then
            echo "[DRY RUN] Would replace core helper module: $target"
        else
            rm -f "$target"
        fi
    fi

    if [[ "$DRY_RUN" == true ]]; then
        echo "[DRY RUN] Would restore core helper module: $target -> $src"
    else
        ln -s "$src" "$target"
        echo "Restored core helper module: $target -> $src"
    fi
done
