#!/bin/bash

OWNER="dennykorsukewitz"
mapfile -t REPOSITORIES < <(gh search repos --owner "$OWNER" --topic "metrics-npm" --jq '.[].name' --json name | sort)

declare -A REPOSITORYCOUNTER
JSON_TOTAL='['
JSON_DAILY='['

DATA_TOTAL='{}'
DATA_DAILY='{}'

COUNT_INSTALL_TOTAL=0

CURRENT_JSON_DAILY=$(jq . ./.github/metrics/data/npm-daily.json)
CURRENT_JSON_TOTAL=$(jq . ./.github/metrics/data/npm-total.json)

# Get yesterday's date
TIMESTAMP=$(date -u -d '1 day ago' +"%Y-%m-%d")
#TIMESTAMP_MAC=$(date -v -1d +"%Y-%m-%dT00:00:00Z")

# TIMESTAMP="2024-03-07"
START_TIMESTAMP=$TIMESTAMP
END_TIMESTAMP=$TIMESTAMP

# START_TIMESTAMP="2024-03-05"
# END_TIMESTAMP="2024-03-05"

echo "TIMESTAMP: $TIMESTAMP"
echo "START_TIMESTAMP: $START_TIMESTAMP"
echo "END_TIMESTAMP: $END_TIMESTAMP"

for REPOSITORY in "${REPOSITORIES[@]}"; do
  echo -e "\n-----------$REPOSITORY-----------"

  NPM_REPOSITORY=${REPOSITORY//npm-/}
  NPM_REPOSITORY=$(echo "$NPM_REPOSITORY" | sed 's/[A-Z]/ &/g' | xargs | sed 's/Git Hub/GitHub/g' | sed 's/ /%20/g')

  # Get the download counts
  RESPONSE_JSON=$(curl -s "https://api.npmjs.org/downloads/point/${START_TIMESTAMP}:${END_TIMESTAMP}/${NPM_REPOSITORY}")

  if [ -z "$RESPONSE_JSON" ] ; then
    echo -e "❌ No RESPONSE_JSON received."
    exit 1
  fi

  # Parse the download counts
  COUNT_INSTALL=0
  COUNT_INSTALL=$(echo "$RESPONSE_JSON" | jq '.downloads')

  echo "$RESPONSE_JSON"
  echo "COUNT_INSTALL: $COUNT_INSTALL"

  REPOSITORYCOUNTER[$REPOSITORY]=$(( REPOSITORYCOUNTER[$REPOSITORY] + "$COUNT_INSTALL" ));
done

TIMESTAMP="${TIMESTAMP}T00:00:00Z"

echo '------------------------------------'
for REPOSITORY in "${!REPOSITORYCOUNTER[@]}"
do

  CURRENT_COUNT_INSTALL=$(echo "$CURRENT_JSON_TOTAL" | jq --arg REPOSITORY "$REPOSITORY" '[.[] | select(.[$REPOSITORY] != null)] | last | .[$REPOSITORY]' | sed 's/"//g')

  COUNT_INSTALL_TOTAL=$(( REPOSITORYCOUNTER[$REPOSITORY] + "$CURRENT_COUNT_INSTALL" ));

  echo "| ${REPOSITORY} => ${REPOSITORYCOUNTER[${REPOSITORY}]} / ${COUNT_INSTALL_TOTAL}"

  DATA_DAILY=$(
    echo "$DATA_DAILY" | jq ". + {\"date\": \"${TIMESTAMP}\"}"
  )
  DATA_DAILY=$(
    echo "$DATA_DAILY" | jq ". + {\"$REPOSITORY\": \"${REPOSITORYCOUNTER[${REPOSITORY}]}\"}"
  )

  if [[ "${REPOSITORYCOUNTER[${REPOSITORY}]}" == "0" ]]; then
    continue
  fi

  DATA_TOTAL=$(
    echo "$DATA_TOTAL" | jq ". + {\"date\": \"${TIMESTAMP}\"}"
  )
  DATA_TOTAL=$(
    echo "$DATA_TOTAL" | jq ". + {\"$REPOSITORY\": \"${COUNT_INSTALL_TOTAL}\"}"
  )
done
echo '------------------------------------'

JSON_TOTAL+=$DATA_TOTAL
JSON_TOTAL+=']'

JSON_DAILY+=$DATA_DAILY
JSON_DAILY+=']'

# Check if the current JSON data contains an entry with the specified timestamp and delete it
if [[ $(echo "$CURRENT_JSON_DAILY" | jq --arg TIMESTAMP "$TIMESTAMP" '.[] | select(.date == $TIMESTAMP)') ]]; then
  CURRENT_JSON_DAILY=$(echo "$CURRENT_JSON_DAILY" | jq --arg TIMESTAMP "$TIMESTAMP" 'map(select(.date != $TIMESTAMP))')
  echo "Element with .date $TIMESTAMP deleted from .github/metrics/data/npm-daily.json"
fi

# Check if the current JSON data contains an entry with the specified timestamp and delete it
if [[ $(echo "$CURRENT_JSON_TOTAL" | jq --arg TIMESTAMP "$TIMESTAMP" '.[] | select(.date == $TIMESTAMP)') ]]; then
  CURRENT_JSON_TOTAL=$(echo "$CURRENT_JSON_TOTAL" | jq --arg TIMESTAMP "$TIMESTAMP" 'map(select(.date != $TIMESTAMP))')
  echo "Element with .date $TIMESTAMP deleted from .github/metrics/data/npm-total.json"
fi

if [[ "$JSON_DAILY"  != "[{}]" ]]; then
  jq --argjson arr1 "$JSON_DAILY" --argjson arr2 "$CURRENT_JSON_DAILY" -n '$arr2 + $arr1 | sort_by(.date)' > ./.github/metrics/data/npm-daily.json
fi
if [[ "$JSON_TOTAL"  != "[{}]" ]]; then
  jq --argjson arr1 "$JSON_TOTAL" --argjson arr2 "$CURRENT_JSON_TOTAL" -n '$arr2 + $arr1 | sort_by(.date)' > ./.github/metrics/data/npm-total.json
fi
