#!/bin/bash

SRC="${PWD}"
declare -r FHEM_DIR="/opt/fhem"

# Whitelist – nur diese Hauptordner werden verarbeitet
WHITELIST=("t" "FHEM" "lib")

# Als-ob-Modus aktivieren (Standard: false, kann mit "--dry-run" aktiviert werden)
DRY_RUN=false
if [[ "$1" == "--dry-run" ]]; then
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

# Für jedes Muster der Whitelist suchen wir rekursiv
for pattern in "${WHITELIST[@]}"; do
    find "$SRC/$pattern" -mindepth 1 -print0 2>/dev/null | sort -z | while IFS= read -r -d '' item; do
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

        if [[ -d "$item" ]]; then
            # Falls es sich um einen Ordner handelt
            if [[ ! -e "$target" ]]; then
                if [[ "$DRY_RUN" == true ]]; then
                    echo "[DRY RUN] Would create directory link: $target -> $item"
                else
                    ln -s "$item" "$target"
                    echo "Created directory link: $target -> $item"
                fi
                # Speichere diesen Ordner als "virtuell verlinkt"
                LINKED_DIRS+=("$rel_path")
            fi
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
