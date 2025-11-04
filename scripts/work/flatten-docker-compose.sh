#!/usr/bin/env bash
set -euo pipefail

# ----------------------------------------------------------
# Flatten a multi-file Docker Compose setup
# keeping only active services from the main compose file,
# preserving networks from the main compose.
# ----------------------------------------------------------

# --- Colors and styles ---
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'
FAINT='\033[2m'
ITALIC='\033[3m'

[[ -t 1 ]] || { RED=""; GREEN=""; CYAN=""; NC=""; FAINT=""; ITALIC=""; }

# --- Files ---
main_compose="docker-compose.yml"
override_compose="docker-compose.override.yml"
output_file="docker-compose.flat.yml"

# --- Logging ---
fail() { echo -e "${FAINT}${RED}❌${NC} ${ITALIC}${RED}$*${NC}" >&2; exit 1; }
info() { echo -e "${FAINT}${CYAN}🔍${NC} ${ITALIC}${CYAN}$*${NC}" >&2; }
success() { echo -e "${FAINT}${GREEN}✔${NC} ${ITALIC}${GREEN}$*${NC}" >&2; }

# --- Prerequisites ---
command -v yq >/dev/null 2>&1 || fail "yq v4+ is required but not installed."
[[ -f "$main_compose" ]] || fail "$main_compose not found"

# --- Read includes ---
info "Reading includes from $main_compose ..."
includes=()
if yq -e 'has("include")' "$main_compose" >/dev/null 2>&1; then
  while IFS= read -r f; do
    includes+=("$f")
  done < <(yq -e '.include[]' "$main_compose" 2>/dev/null || true)
fi

# --- Detect active services ---
info "Detecting active services ..."
services=()
if [[ "$(yq -e 'has("services")' "$main_compose" 2>/dev/null)" =~ true ]]; then
  while IFS= read -r svc; do
    [[ -n "$svc" ]] && services+=("$svc")
  done < <(yq -e '.services | keys | .[]' "$main_compose" 2>/dev/null || true)
fi

[[ ${#services[@]} -gt 0 ]] || info "No active services found in $main_compose."
echo services: "${services[*]}"

# --- Start with empty YAML ---
tmp_file=$(mktemp)
echo "{}" > "$tmp_file"

# --- Merge included files ---
# for f in "${includes[@]}"; do
#   if [[ -f "$f" ]]; then
#     info "Merging include: $f"
#     yq eval-all '. as $item ireduce ({}; . *+ $item)' "$tmp_file" "$f" -i
#   else
#     info "Skipping missing include: $f"
#   fi
# done

# --- Merge each active service safely ---
for svc in "${services[@]}"; do
  info "Processing service: $svc"

  extend_file=$(yq -e ".services.\"$svc\".extends.file // empty" "$main_compose" 2>/dev/null || true)
  extend_service=$(yq -e ".services.\"$svc\".extends.service // empty" "$main_compose" 2>/dev/null || true)

  tmp_ext=$(mktemp)
  tmp_main=$(mktemp)

  # Get extended service or empty
  if [[ -n "$extend_file" && -n "$extend_service" ]] && [[ -f "$extend_file" ]]; then
    yq eval ".services.\"$extend_service\" // {}" "$extend_file" > "$tmp_ext"
  else
    echo "{}" > "$tmp_ext"
  fi

  # Main service without extends
  yq eval ".services.\"$svc\" | del(.extends)" "$main_compose" > "$tmp_main"

  # Merge extended + main service
  merged_service=$(yq eval-all '. as $item ireduce ({}; . *+ $item)' "$tmp_ext" "$tmp_main")

  # Insert merged service safely
  tmp_merge=$(mktemp)
  echo "$merged_service" > "$tmp_merge"
  yq eval ".services.\"$svc\" = load(\"$tmp_merge\")" "$tmp_file" -i

  rm -f "$tmp_ext" "$tmp_main" "$tmp_merge"
done

# --- Apply override if present ---
if [[ -f "$override_compose" ]]; then
  info "Applying override file $override_compose ..."
  yq eval-all '. as $item ireduce ({}; . *+ $item)' "$tmp_file" "$override_compose" -i
fi

# --- Preserve networks from main compose ---
if yq -e 'has("networks")' "$main_compose" >/dev/null 2>&1; then
  info "Preserving networks from main compose"
  tmp_networks=$(mktemp)
  yq eval '.networks' "$main_compose" > "$tmp_networks"
  yq eval ".networks = load(\"$tmp_networks\")" "$tmp_file" -i
  rm -f "$tmp_networks"
fi

# --- Validate and write output ---
if [[ ! -s "$tmp_file" ]]; then
  fail "Merged file is empty or invalid"
fi

mv "$tmp_file" "$output_file"
success "Flattened compose written to $output_file"
info "You can now run it with: docker compose -f $output_file up -d"
