#!/usr/bin/env bash

OWNER="dennykorsukewitz"

# ------------------------------------
# SUBLIME
# ------------------------------------

# https://packagecontrol.io/packages/"$SUBLIME_REPOSITORY".json
mapfile -t REPOSITORIES < <(gh search repos --owner "$OWNER" --topic "metrics-sublime" --jq '.[].name' --json name | sort)

declare -A REPOSITORYCOUNTER
JSON_DAILY='['
DATA_DAILY='{}'
CURRENT_JSON_DAILY=$(jq . ./.github/metrics/data/daily.json)

TIMESTAMP=$(date -u -v-1d +"%Y-%m-%dT00:00:00Z")
# TIMESTAMP="2024-02-23T00:00:00Z"
echo "TIMESTAMP: $TIMESTAMP"

for REPOSITORY in "${REPOSITORIES[@]}"; do
  echo -e "\n-----------$REPOSITORY-----------"

    SUBLIME_REPOSITORY=${REPOSITORY//Sublime-/}
    SUBLIME_REPOSITORY=$(echo "$SUBLIME_REPOSITORY" | sed 's/[A-Z]/ &/g' | xargs | sed 's/Git Hub/GitHub/g' | sed 's/ /%20/g')

    RESPONSE_JSON=$(curl https://packagecontrol.io/packages/"$SUBLIME_REPOSITORY".json)

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

echo '------------------------------------'
for REPOSITORY in "${!REPOSITORYCOUNTER[@]}"
do

  echo "| ${REPOSITORY} => ${REPOSITORYCOUNTER[${REPOSITORY}]}"

  DATA_DAILY=$(
    echo "$DATA_DAILY" | jq ". + {\"date\": \"${TIMESTAMP}\"}"
  )
  DATA_DAILY=$(
    echo "$DATA_DAILY" | jq ". + {\"$REPOSITORY\": \"${REPOSITORYCOUNTER[${REPOSITORY}]}\"}"
  )

done
echo '------------------------------------'

# ------------------------------------
# VSCODE
# ------------------------------------

mapfile -t REPOSITORIES < <(gh search repos --owner "$OWNER" --topic "vsc" --jq '.[].name' --json name | sort)

declare -A REPOSITORYCOUNTER

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

  echo "| ${REPOSITORY} => ${REPOSITORYCOUNTER[${REPOSITORY}]}"

  DATA_DAILY=$(
    echo "$DATA_DAILY" | jq ". + {\"date\": \"${TIMESTAMP}\"}"
  )
  DATA_DAILY=$(
    echo "$DATA_DAILY" | jq ". + {\"$REPOSITORY\": \"${REPOSITORYCOUNTER[${REPOSITORY}]}\"}"
  )

done
echo '------------------------------------'

JSON_DAILY+=$DATA_DAILY
JSON_DAILY+=']'

if [[ "$JSON_DAILY"  != "[{}]" ]]; then
  jq --argjson arr1 "$JSON_DAILY" --argjson arr2 "$CURRENT_JSON_DAILY" -n '$arr2 + $arr1 | sort_by(.date)' > ./.github/metrics/data/daily.json
fi