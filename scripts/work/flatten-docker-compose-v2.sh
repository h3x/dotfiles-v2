#!/usr/bin/env bash
set -euo pipefail

# ----------------------------------------------------------
# Flatten Docker Compose setup with include files,
# resolving extends, applying overrides, preserving
# networks and secrets from main compose.
# ----------------------------------------------------------

# --- Colors & styles ---
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'
FAINT='\033[2m'
ITALIC='\033[3m'
[[ -t 1 ]] || { RED=""; GREEN=""; CYAN=""; NC=""; FAINT=""; ITALIC=""; }

# --- Files ---
MAIN_COMPOSE="docker-compose.yml"
OVERRIDE_COMPOSE="docker-compose.override.yml"
OUTPUT_FILE="docker-compose.flat.yml"

# --- Logging ---
fail() { echo -e "${FAINT}${RED}❌${NC} ${ITALIC}${RED}$*${NC}" >&2; exit 1; }
info() { echo -e "${FAINT}${CYAN}🔍${NC} ${ITALIC}${CYAN}$*${NC}" >&2; }
success() { echo -e "${FAINT}${GREEN}✔${NC} ${ITALIC}${GREEN}$*${NC}" >&2; }

# --- Prerequisites ---
command -v yq >/dev/null 2>&1 || fail "yq v4+ is required but not installed."
[[ -f "$MAIN_COMPOSE" ]] || fail "$MAIN_COMPOSE not found"

# --- Start with empty YAML ---
TMP_FILE=$(mktemp)
echo "{}" > "$TMP_FILE"

# --- Preserve networks & secrets from main compose ---
info "Preserving networks and secrets from main compose..."
if yq e 'has("networks")' "$MAIN_COMPOSE" >/dev/null 2>&1; then
  yq e '.networks' "$MAIN_COMPOSE" | yq e '.networks = load("-")' "$TMP_FILE" -i
fi
if yq e 'has("secrets")' "$MAIN_COMPOSE" >/dev/null 2>&1; then
  yq e '.secrets' "$MAIN_COMPOSE" | yq e '.secrets = load("-")' "$TMP_FILE" -i
fi

# --- Process includes ---
info "Processing include files..."
INCLUDES=()
if yq e 'has("include")' "$MAIN_COMPOSE" >/dev/null 2>&1; then
  while IFS= read -r f; do
    INCLUDES+=("$f")
  done < <(yq e '.include[]' "$MAIN_COMPOSE" 2>/dev/null || true)
fi

for INCLUDE_FILE in "${INCLUDES[@]}"; do
  [[ -f "$INCLUDE_FILE" ]] || { info "Skipping missing include: $INCLUDE_FILE"; continue; }
  info "Flattening services from $INCLUDE_FILE..."

  # Get all services in the include file
  SERVICES=$(yq e '.services | keys | .[]' "$INCLUDE_FILE" 2>/dev/null || true)
  for SVC in $SERVICES; do
    # Resolve extends
    EXT_FILE=$(yq e ".services.\"$SVC\".extends.file // \"\"" "$INCLUDE_FILE")
    EXT_SERVICE=$(yq e ".services.\"$SVC\".extends.service // \"\"" "$INCLUDE_FILE")

    TMP_EXT=$(mktemp)
    TMP_MAIN=$(mktemp)

    if [[ -n "$EXT_FILE" && -n "$EXT_SERVICE" && -f "$EXT_FILE" ]]; then
      yq e ".services.\"$EXT_SERVICE\" // {}" "$EXT_FILE" > "$TMP_EXT"
    else
      echo "{}" > "$TMP_EXT"
    fi

    yq e ".services.\"$SVC\" | del(.extends)" "$INCLUDE_FILE" > "$TMP_MAIN"

    MERGED=$(yq e-all '. as $item ireduce ({}; . *+ $item)' "$TMP_EXT" "$TMP_MAIN")

    TMP_MERGED=$(mktemp)
    echo "$MERGED" > "$TMP_MERGED"
    yq e ".services.\"$SVC\" = load(\"$TMP_MERGED\")" "$TMP_FILE" -i

    rm -f "$TMP_EXT" "$TMP_MAIN" "$TMP_MERGED"
  done
done

# --- Apply override file ---
if [[ -f "$OVERRIDE_COMPOSE" ]]; then
  info "Applying override file $OVERRIDE_COMPOSE..."
  yq e-all '. as $item ireduce ({}; . *+ $item)' "$TMP_FILE" "$OVERRIDE_COMPOSE" -i
fi

# --- Validate ---
[[ -s "$TMP_FILE" ]] || fail "Flattened compose is empty or invalid"

mv "$TMP_FILE" "$OUTPUT_FILE"
success "Flattened compose written to $OUTPUT_FILE"
info "Run it with: docker compose -f $OUTPUT_FILE up -d"
