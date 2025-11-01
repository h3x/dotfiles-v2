
#!/usr/bin/env bash
# Fast netscan: outputs [ipaddress : computer name] for live hosts

set -eu
shopt -s extglob

for cmd in ip awk seq; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "ERROR: required command '$cmd' not found in PATH." >&2
    exit 2
  fi
done

IFACE="${1-}"
if [[ -z "$IFACE" ]]; then
  IFACE="$(ip route get 1.1.1.1 2>/dev/null | awk '/dev/ {for(i=1;i<=NF;i++) if ($i=="dev") print $(i+1)}' | head -n1 || true)"
fi
if [[ -z "$IFACE" ]]; then
  IFACE="$(ip -o -4 addr show up primary scope global | awk '{print $2; exit}')"
fi
if [[ -z "$IFACE" ]]; then
  echo "ERROR: no suitable network interface found." >&2
  exit 3
fi

CIDR="$(ip -o -f inet addr show dev "$IFACE" | awk '{print $4}' | head -n1 || true)"
if [[ -z "$CIDR" ]]; then
  ADDR="$(ip -o -4 addr show dev "$IFACE" | awk '{print $4}' | head -n1 | cut -d/ -f1 || true)"
  if [[ -z "$ADDR" ]]; then
    echo "ERROR: no IPv4 on $IFACE." >&2
    exit 4
  fi
  CIDR="$ADDR/24"
fi

IP="${CIDR%/*}"
PREFIX="${CIDR#*/}"
if ! [[ "$PREFIX" =~ ^[0-9]+$ ]] || (( PREFIX < 1 || PREFIX > 32 )); then
  PREFIX=24
fi

ip2int() { local IFS=.; read -r a b c d <<< "$1"; echo $(( (a<<24)+(b<<16)+(c<<8)+d )); }
int2ip() { local ip=$1; printf "%u.%u.%u.%u" $(( (ip>>24)&255 )) $(( (ip>>16)&255 )) $(( (ip>>8)&255 )) $(( ip&255 )); }

ip_int=$(ip2int "$IP")
netmask_int=$(( 0xFFFFFFFF ^ ((1 << (32 - PREFIX)) - 1) ))
network_int=$(( ip_int & netmask_int ))
broadcast_int=$(( network_int | ((1 << (32 - PREFIX)) - 1) ))
start_ip=$(( network_int + 1 ))
end_ip=$(( broadcast_int - 1 ))

# Generate IP list
ips=()
for i in $(seq $start_ip $end_ip); do
  ips+=( "$(int2ip $i)" )
done

# Use fping if available for fast sweep, else fallback to ping
if command -v fping >/dev/null 2>&1; then
  live_ips=$(printf "%s\n" "${ips[@]}" | fping -a -q -g 2>/dev/null)
else
  live_ips=$(printf "%s\n" "${ips[@]}" | xargs -P 200 -I{} bash -c 'ping -c1 -W1 -n -q {} >/dev/null 2>&1 && echo {}' || true)
fi

CHOICE=$(printf "%s\n" "$live_ips" | xargs -P 50 -I{} bash -c '
  ip="$1"
  name=$(getent hosts "$ip" | awk "{print \$2}" | head -n1)
  [[ -z "$name" ]] && name="(unknown)"
  echo "[$ip : $name]"
' _ {} | rofi -dmenu -i -p "Select host:")

[ -z "$CHOICE" ] && exit 0
IP=$(echo "$CHOICE" | awk -F'[][]' '{print $2}' | awk -F' : ' '{print $1}')


# Copy to clipboard (supports xclip or wl-copy)
command -v wl-copy >/dev/null && echo -n "$IP" | wl-copy || echo -n "$IP" | xclip -selection clipboard
