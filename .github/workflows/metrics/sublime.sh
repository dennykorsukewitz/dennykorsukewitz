#!/usr/bin/env bash

OWNER="dennykorsukewitz"

DAILY_FILE="./.github/metrics/data/sublime-daily.json"
TOTAL_FILE="./.github/metrics/data/sublime-total.json"

DEFAULT_REPOSITORIES=(
  "Sublime-AddFolderToProject"
  "Sublime-GitHubFileFetcher"
  "Sublime-QuoteWithMarker"
)

ensure_json_array_file() {
  local file="$1"
  if [ ! -s "$file" ] || ! jq -e 'type == "array"' "$file" >/dev/null 2>&1; then
    echo '[]' > "$file"
  fi
}

ensure_json_array_file "$DAILY_FILE"
ensure_json_array_file "$TOTAL_FILE"

to_int() {
  local value="$1"
  value=${value//\"/}
  value=${value// /}
  case "$value" in
    ''|null|*[!0-9-]*) echo 0 ;;
    *) echo "$value" ;;
  esac
}

last_total_for_repo() {
  local repository="$1"
  local file="$2"
  jq --arg REPOSITORY "$repository" -r '
    [.[] | select(.[$REPOSITORY] != null)] | last |
    (.[$REPOSITORY] | if type == "string" then (tonumber? // 0) elif type == "number" then . else 0 end) // 0
  ' "$file"
}

REPOSITORIES=()
while IFS= read -r repo; do
  if [ -n "$repo" ]; then
    REPOSITORIES+=("$repo")
  fi
done < <(gh search repos --owner "$OWNER" --topic "metrics-sublime" --jq '.[].name' --json name 2>/dev/null | sort)

if [ -z "${REPOSITORIES[0]}" ]; then
  REPOSITORIES=("${DEFAULT_REPOSITORIES[@]}")
  echo "Using default Sublime repositories: ${REPOSITORIES[*]}"
fi

PROCESSED_REPOS=()
PROCESSED_COUNTS=()

# Public API: https://packagecontrol.io/packages/<Package Name>.json
fetch_packagecontrol_json() {
  local package_slug="$1"
  curl -fsS --http1.1 --compressed --silent \
    --retry 5 --retry-all-errors --retry-delay 3 \
    -A "dennykorsukewitz-github-metrics" \
    "https://packagecontrol.io/packages/${package_slug}.json"
}

sublime_package_slug() {
  local repository_name="$1"
  local sublime_repository="${repository_name//Sublime-/}"

  echo "$sublime_repository" | sed 's/[A-Z]/ &/g' | xargs | sed 's/Git Hub/GitHub/g' | sed 's/ /%20/g'
}

for REPOSITORY in "${REPOSITORIES[@]}"; do
  echo -e "\n-----------$REPOSITORY-----------"

  PACKAGE_SLUG=$(sublime_package_slug "$REPOSITORY")
  echo "PACKAGE_SLUG: $PACKAGE_SLUG"

  if ! RESPONSE_JSON=$(fetch_packagecontrol_json "$PACKAGE_SLUG"); then
    echo "⚠️  Skipping $REPOSITORY: packagecontrol request failed for ${PACKAGE_SLUG}.json"
    continue
  fi

  if ! echo "$RESPONSE_JSON" | jq -e '.installs.daily.dates[1]' >/dev/null 2>&1; then
    echo "⚠️  Skipping $REPOSITORY: unexpected packagecontrol JSON"
    continue
  fi

  DATE=$(echo "$RESPONSE_JSON" | jq -r '.installs.daily.dates[1]')
  TIMESTAMP="${DATE}T00:00:00Z"

  REPO_COUNT=0
  for i in 0 1 2; do
    COUNT_INSTALL=$(to_int "$(echo "$RESPONSE_JSON" | jq -r ".installs.daily.data[$i].totals[1] // 0")")
    REPO_COUNT=$(( REPO_COUNT + COUNT_INSTALL ))
  done

  PROCESSED_REPOS+=("$REPOSITORY")
  PROCESSED_COUNTS+=("$REPO_COUNT")
done

if [ -z "${PROCESSED_REPOS[0]}" ]; then
  echo "❌ No package stats collected from packagecontrol.io."
  exit 1
fi

if [ -z "$TIMESTAMP" ]; then
  echo "❌ TIMESTAMP could not be determined."
  exit 1
fi

if jq -e --arg TIMESTAMP "$TIMESTAMP" '.[] | select(.date == $TIMESTAMP)' "$DAILY_FILE" >/dev/null; then
  jq --arg TIMESTAMP "$TIMESTAMP" 'map(select(.date != $TIMESTAMP))' "$DAILY_FILE" > "${DAILY_FILE}.tmp" && mv "${DAILY_FILE}.tmp" "$DAILY_FILE"
  echo "Element with .date $TIMESTAMP deleted from $DAILY_FILE"
fi

if jq -e --arg TIMESTAMP "$TIMESTAMP" '.[] | select(.date == $TIMESTAMP)' "$TOTAL_FILE" >/dev/null; then
  jq --arg TIMESTAMP "$TIMESTAMP" 'map(select(.date != $TIMESTAMP))' "$TOTAL_FILE" > "${TOTAL_FILE}.tmp" && mv "${TOTAL_FILE}.tmp" "$TOTAL_FILE"
  echo "Element with .date $TIMESTAMP deleted from $TOTAL_FILE"
fi

JSON_TOTAL='['
JSON_DAILY='['
DATA_TOTAL='{}'
DATA_DAILY='{}'

echo '------------------------------------'
for idx in "${!PROCESSED_REPOS[@]}"; do
  REPOSITORY="${PROCESSED_REPOS[$idx]}"
  REPO_COUNT=$(to_int "${PROCESSED_COUNTS[$idx]}")

  CURRENT_COUNT_INSTALL=$(to_int "$(last_total_for_repo "$REPOSITORY" "$TOTAL_FILE")")

  COUNT_INSTALL_TOTAL=$(( REPO_COUNT + CURRENT_COUNT_INSTALL ))

  echo "| ${REPOSITORY} => ${REPO_COUNT} / ${COUNT_INSTALL_TOTAL}"

  DATA_DAILY=$(echo "$DATA_DAILY" | jq ". + {\"date\": \"${TIMESTAMP}\"}")
  DATA_DAILY=$(echo "$DATA_DAILY" | jq ". + {\"$REPOSITORY\": \"${REPO_COUNT}\"}")

  if [ "$REPO_COUNT" = "0" ]; then
    continue
  fi

  DATA_TOTAL=$(echo "$DATA_TOTAL" | jq ". + {\"date\": \"${TIMESTAMP}\"}")
  DATA_TOTAL=$(echo "$DATA_TOTAL" | jq ". + {\"$REPOSITORY\": \"${COUNT_INSTALL_TOTAL}\"}")
done
echo '------------------------------------'

JSON_TOTAL+=$DATA_TOTAL
JSON_TOTAL+=']'

JSON_DAILY+=$DATA_DAILY
JSON_DAILY+=']'

if [ "$JSON_DAILY" != "[{}]" ]; then
  echo "$JSON_DAILY" > temp_daily.json
  jq -s 'add | sort_by(.date)' temp_daily.json "$DAILY_FILE" > "${DAILY_FILE}.tmp" && mv "${DAILY_FILE}.tmp" "$DAILY_FILE"
  rm -f temp_daily.json
fi

if [ "$JSON_TOTAL" != "[{}]" ]; then
  echo "$JSON_TOTAL" > temp_total.json
  jq -s 'add | sort_by(.date)' temp_total.json "$TOTAL_FILE" > "${TOTAL_FILE}.tmp" && mv "${TOTAL_FILE}.tmp" "$TOTAL_FILE"
  rm -f temp_total.json
fi
