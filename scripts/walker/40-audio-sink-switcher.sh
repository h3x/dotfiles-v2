switch_audio() {
  local type="$1" # "sink" or "source"
  local icon_default icon_other
  if [ "$type" = "sink" ]; then
    icon_default=""
    icon_other=""
    DEFAULT=$(pactl info | awk '/Default Sink/ {print $3}')
    LIST_CMD="pactl list sinks"
    MOVE_CMD="sink-inputs"
    ACTION="set-default-sink"
  else
    icon_default=""
    icon_other=""
    DEFAULT=$(pactl info | awk '/Default Source/ {print $3}')
    LIST_CMD="pactl list sources"
    MOVE_CMD="source-outputs"
    ACTION="set-default-source"
  fi

  declare -A DEVICES
  CURRENT_NAME=""

  while IFS= read -r line; do
    if [[ $line =~ ^$type\ #[0-9]+ ]]; then
      CURRENT_NAME=""
    fi
    if [[ $line =~ ^[[:space:]]*Name:\ (.*) ]]; then
      CURRENT_NAME="${BASH_REMATCH[1]}"
    fi
    if [[ $line =~ ^[[:space:]]*Description:\ (.*) ]] && [ -n "$CURRENT_NAME" ]; then
      DESC="${BASH_REMATCH[1]}"
      DEVICES["$DESC"]="$CURRENT_NAME"
      CURRENT_NAME=""
    fi
  done < <($LIST_CMD)

  # Build menu
  MENU=""
  for d in "${!DEVICES[@]}"; do
    if [ "${DEVICES[$d]}" = "$DEFAULT" ]; then
      MENU+="$icon_default  $d *\n"
    else
      MENU+="$icon_other  $d\n"
    fi
  done

  CHOICE=$(echo -e "$MENU" | walker --dmenu -p "Select $(echo $type | sed 's/./\U&/'):")

  [ -z "$CHOICE" ] && return 0

  # Remove icons/* for mapping
  KEY=$(echo "$CHOICE" | sed 's/^[^ ]*  //' | sed 's/ \*$//')
  DEV="${DEVICES[$KEY]}"

  # Set default
  pactl $ACTION "$DEV"

  # Move existing streams (if any)
  for INPUT in $(pactl list short $MOVE_CMD | awk '{print $1}'); do
    pactl move-$type-input "$INPUT" "$DEV" 2>/dev/null
  done

  notify-send "🔊 Audio $type Switched" "$KEY"
}

# Switch output first
switch_audio sink

# Then switch input
switch_audio source
