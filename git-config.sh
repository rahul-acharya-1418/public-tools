#!/bin/bash

# Check if input file is provided
if [ -z "$1" ]; then
  echo "Usage: $0 <file-with-domains>"
  exit 1
fi

FILE="$1"

while IFS= read -r DOMAIN; do
  [ -z "$DOMAIN" ] && continue

  echo "[+] Gathering subs for $DOMAIN"

  subfinder -d "$DOMAIN" -silent >> "$DOMAIN.txt"
  findomain -t "$DOMAIN" -q >> "$DOMAIN.txt"
  assetfinder -subs-only "$DOMAIN" >> "$DOMAIN.txt"

  # 🔥 Deduplicate + remove *.
  sort -u "$DOMAIN.txt" | sed 's/^\*\.//' > "$DOMAIN.clean.txt"
  mv "$DOMAIN.clean.txt" "$DOMAIN.txt"

  # DNS resolve
  dnsx -silent < "$DOMAIN.txt" > "dnsx.$DOMAIN.txt"

  # HTTP probe
  httpx -silent < "dnsx.$DOMAIN.txt" > "httpx.$DOMAIN.txt"

  # Nuclei scan
  nuclei -t ~/nuclei-templates/http/exposures/configs/git-config.yaml \
    < "httpx.$DOMAIN.txt" | tee "__nuclei.$DOMAIN.txt"

done < "$FILE"
