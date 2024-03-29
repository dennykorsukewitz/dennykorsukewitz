#!/bin/bash

OWNER="dennykorsukewitz"

# https://packagecontrol.io/packages/"$SUBLIME_REPOSITORY".json
mapfile -t REPOSITORIES < <(gh search repos --owner "$OWNER" --topic "metrics-sublime" --jq '.[].name' --json name | sort)

declare -A REPOSITORYCOUNTER

JSON_TOTAL='['
JSON_DAILY='['

DATA_TOTAL='{}'
DATA_DAILY='{}'

COUNT_INSTALL_TOTAL=0

CURRENT_JSON_DAILY=$(jq . ./.github/metrics/data/sublime-daily.json)
CURRENT_JSON_TOTAL=$(jq . ./.github/metrics/data/sublime-total.json)

for REPOSITORY in "${REPOSITORIES[@]}"; do
  echo -e "\n-----------$REPOSITORY-----------"

  SUBLIME_REPOSITORY=${REPOSITORY//Sublime-/}
  SUBLIME_REPOSITORY=$(echo "$SUBLIME_REPOSITORY" | sed 's/[A-Z]/ &/g' | xargs | sed 's/Git Hub/GitHub/g' | sed 's/ /%20/g')

  RESPONSE_JSON=$(curl https://packagecontrol.io/packages/"$SUBLIME_REPOSITORY".json)

  if [ -z "$RESPONSE_JSON" ] ; then
    echo -e "❌ No RESPONSE_JSON received."
    exit 1
  fi

  if [ -z "$RESPONSE_JSON" ] ; then
    echo -e "❌ No RESPONSE_JSON received."
    exit 1
  fi

  DATE=$(echo "$RESPONSE_JSON" | jq --compact-output -r ".installs.daily.dates[1]")
  TIMESTAMP="${DATE}T00:00:00Z"

  COUNT_INSTALL=0
  for i in {0..2}
  do
    COUNT_INSTALL=$(echo "$RESPONSE_JSON" | jq --compact-output -r ".installs.daily.data[$i].totals[1]")
    REPOSITORYCOUNTER[$REPOSITORY]=$(( REPOSITORYCOUNTER[$REPOSITORY] + "$COUNT_INSTALL" ));
  done
done

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


if [[ "$JSON_DAILY"  != "[{}]" ]]; then
  jq --argjson arr1 "$JSON_DAILY" --argjson arr2 "$CURRENT_JSON_DAILY" -n '$arr2 + $arr1 | sort_by(.date)' > ./.github/metrics/data/sublime-daily.json
fi
if [[ "$JSON_TOTAL"  != "[{}]" ]]; then
  jq --argjson arr1 "$JSON_TOTAL" --argjson arr2 "$CURRENT_JSON_TOTAL" -n '$arr2 + $arr1 | sort_by(.date)' > ./.github/metrics/data/sublime-total.json
fi
