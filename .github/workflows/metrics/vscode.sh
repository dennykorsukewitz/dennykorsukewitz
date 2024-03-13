#!/bin/bash

OWNER="dennykorsukewitz"

mapfile -t REPOSITORIES < <(gh search repos --owner "$OWNER" --topic "vsc" --jq '.[].name' --json name | sort)

declare -A REPOSITORYCOUNTER

JSON_TOTAL='['
JSON_DAILY='['

DATA_TOTAL='{}'
DATA_DAILY='{}'

COUNT_INSTALL_TOTAL=0

CURRENT_JSON_DAILY=$(jq . ./.github/metrics/data/vscode-daily.json)
CURRENT_JSON_TOTAL=$(jq . ./.github/metrics/data/vscode-total.json)

TIMESTAMP=$(date -u -d '1 day ago' +"%Y-%m-%dT00:00:00Z")
#TIMESTAMP_MAC=$(date -v -1d +"%Y-%m-%dT00:00:00Z")

# TIMESTAMP="2024-03-12T00:00:00Z"
echo "TIMESTAMP: $TIMESTAMP"
echo "TIMESTAMP_MAC: $TIMESTAMP_MAC"

for REPOSITORY in "${REPOSITORIES[@]}"; do
  echo -e "\n-----------$REPOSITORY-----------"

    if [ -z "$VSC_PAT" ] ; then
      echo -e "❌ VSC PAT is not defined."
      exit 1
    fi

    VSCODE_REPOSITORY=${REPOSITORY//VSCode-/}

    RESPONSE_JSON=$(curl -u "$OWNER":"$VSC_PAT" -X GET https://marketplace.visualstudio.com/_apis/gallery/publishers/dennykorsukewitz/extensions/"$VSCODE_REPOSITORY"/stats)

    if [ -z "$RESPONSE_JSON" ] ; then
      echo -e "❌ No RESPONSE_JSON received."
      exit 1
    fi

    readarray -t STATS < <(echo "$RESPONSE_JSON" | jq --compact-output -r '.dailyStats |= sort_by(.statisticDate) | .dailyStats[]')

    for ROW in "${STATS[@]}"; do

      DATE=$(echo "$ROW" | jq '.statisticDate' | sed 's/\"//g')
      COUNT_INSTALL=0

      if [[ "$DATE" == "$TIMESTAMP" ]]; then

        COUNT_INSTALL=$(echo "$ROW" | jq '.counts.installCount' | sed 's/\"//g')

        if [[ "$COUNT_INSTALL" == "null" ]]; then
          COUNT_INSTALL=0
        fi
      fi

      REPOSITORYCOUNTER[$REPOSITORY]=$(( REPOSITORYCOUNTER[$REPOSITORY] + "$COUNT_INSTALL" ));
    done
done

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
  jq --argjson arr1 "$JSON_DAILY" --argjson arr2 "$CURRENT_JSON_DAILY" -n '$arr2 + $arr1 | sort_by(.date)' > ./.github/metrics/data/vscode-daily.json
fi
if [[ "$JSON_TOTAL"  != "[{}]" ]]; then
  jq --argjson arr1 "$JSON_TOTAL" --argjson arr2 "$CURRENT_JSON_TOTAL" -n '$arr2 + $arr1 | sort_by(.date)' > ./.github/metrics/data/vscode-total.json
fi


