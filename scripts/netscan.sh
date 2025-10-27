#!/usr/bin/env bash
# netscan.sh - scan local IPv4 network, print IP and hostname
# Usage: ./netscan.sh [optional: interface]
set -eu
shopt -s extglob

for cmd in ip ping xargs getent awk seq; do
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
  echo "Warning: couldn't auto-detect interface. Defaulting to first non-loopback interface." >&2
  IFACE="$(ip -o -4 addr show up primary scope global | awk '{print $2; exit}')"
fi
if [[ -z "$IFACE" ]]; then
  echo "ERROR: no suitable network interface found." >&2
  exit 3
fi

CIDR="$(ip -o -f inet addr show dev "$IFACE" | awk '{print $4}' | head -n1 || true)"
if [[ -z "$CIDR" ]]; then
  echo "Warning: couldn't read CIDR for $IFACE. Falling back to /24." >&2
  ADDR="$(ip -o -4 addr show dev "$IFACE" | awk '{print $4}' | head -n1 | cut -d/ -f1 || true)"
  if [[ -z "$ADDR" ]]; then
    echo "ERROR: no IPv4 on $IFACE." >&2
    exit 4
  fi
  CIDR="$ADDR/24"
fi

ip2int() {
  local IFS=.
  read -r a b c d <<< "$1"
  echo $(( (a<<24) + (b<<16) + (c<<8) + d ))
}

int2ip() {
  local ip=$1
  local a=$(( (ip >> 24) & 0xFF ))
  local b=$(( (ip >> 16) & 0xFF ))
  local c=$(( (ip >> 8) & 0xFF ))
  local d=$(( ip & 0xFF ))
  printf "%u.%u.%u.%u" "$a" "$b" "$c" "$d"
}

IP="${CIDR%/*}"
PREFIX="${CIDR#*/}"
if ! [[ "$PREFIX" =~ ^[0-9]+$ ]] || (( PREFIX < 1 || PREFIX > 32 )); then
  echo "Warning: weird prefix $PREFIX; defaulting to 24." >&2
  PREFIX=24
fi

ip_int=$(ip2int "$IP")
netmask_int=$(( 0xFFFFFFFF ^ ((1 << (32 - PREFIX)) - 1) ))
network_int=$(( ip_int & netmask_int ))
broadcast_int=$(( network_int | ((1 << (32 - PREFIX)) - 1) ))

start_ip=$(( network_int + 1 ))
end_ip=$(( broadcast_int - 1 ))

total=$(( end_ip - start_ip + 1 ))
if (( total <= 0 )) || (( total > 65536 )); then
  echo "Network range too large or invalid. Falling back to /24 around $IP." >&2
  PREFIX=24
  netmask_int=$(( 0xFFFFFFFF ^ ((1 << (32 - PREFIX)) - 1) ))
  network_int=$(( ip_int & netmask_int ))
  broadcast_int=$(( network_int | ((1 << (32 - PREFIX)) - 1) ))
  start_ip=$(( network_int + 1 ))
  end_ip=$(( broadcast_int - 1 ))
  total=$(( end_ip - start_ip + 1 ))
fi

echo "Scanning interface: $IFACE  CIDR: $CIDR  Range: $(int2ip $start_ip)-$(int2ip $end_ip)  Hosts: $total" >&2

PARALLEL=${PARALLEL:-$(awk '/^processor/ {c++} END{print c+0}' /proc/cpuinfo)}
if (( PARALLEL < 1 )); then PARALLEL=4; fi
PARALLEL=$(( PARALLEL * 4 ))
if (( PARALLEL > 200 )); then PARALLEL=200; fi

alive_ips_file=$(mktemp)
cleanup() { rm -f "$alive_ips_file"; }
trap cleanup EXIT

generate_seq() {
  local s=$1 e=$2
  seq "$s" "$e"
}

# Export int2ip so child bash processes can call it
export -f int2ip

# ===== FIXED xargs invocation: use -n1 and avoid -I{}
# pass the numeric IP int as $0 to the bash -c script (so we can call int2ip "$0")
generate_seq "$start_ip" "$end_ip" | xargs -P "$PARALLEL" -n1 bash -c '
  ip=$(int2ip "$0")
  if ping -c1 -W1 -n -q "$ip" >/dev/null 2>&1; then
    printf "%s\n" "$ip"
  fi
' > "$alive_ips_file"

if [[ ! -s "$alive_ips_file" ]]; then
  echo "No live hosts detected (ICMP). Try running with sudo and/or use nmap/arp-scan for more methods." >&2
  exit 0
fi

echo
printf "%-16s %-40s %s\n" "IP" "HOSTNAME" "MAC"
printf "%-16s %-40s %s\n" "----------------" "----------------------------------------" "----------------"

while read -r ip; do
  hostname=""
  if hostname=$(getent hosts "$ip" | awk '{print $2; exit}'); then
    :
  fi

  if [[ -z "$hostname" ]]; then
    if command -v host >/dev/null 2>&1; then
      hostname="$(host "$ip" 2>/dev/null | awk -F ' pointer ' '{print $2}' | sed 's/\.$//' | head -n1 || true)"
    fi
  fi

  if [[ -z "$hostname" ]]; then
    if command -v nslookup >/dev/null 2>&1; then
      hostname="$(nslookup "$ip" 2>/dev/null | awk -F'name = ' '/name =/ {print $2}' | sed 's/\.$//' | head -n1 || true)"
    fi
  fi

  if [[ -z "$hostname" ]]; then
    if command -v nmblookup >/dev/null 2>&1; then
      nb=$(nmblookup -A "$ip" 2>/dev/null | awk '/<00>/{print $1; exit}' | sed 's/<.*>//' || true)
      [[ -n "$nb" ]] && hostname="$nb"
    fi
  fi

  mac="$(ip neigh show "$ip" 2>/dev/null | awk '{for(i=1;i<=NF;i++) if ($i ~ /:/) print $i; exit}' || true)"
  [[ -z "$mac" ]] && mac="-"

  if [[ -z "$hostname" ]]; then hostname="(unknown)"; fi
  printf "%-16s %-40s %s\n" "$ip" "$hostname" "$mac"
done < "$alive_ips_file"

exit 0
