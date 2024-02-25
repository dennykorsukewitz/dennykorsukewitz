#!/usr/bin/env bash

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

TIMESTAMP=$(date -u -v-1d +"%Y-%m-%dT00:00:00Z")
# TIMESTAMP="2024-02-20T00:00:00Z"

for REPOSITORY in "${REPOSITORIES[@]}"; do
  echo -e "\n-----------$REPOSITORY-----------"

    VSCODE_REPOSITORY=${REPOSITORY//VSCode-/}

    if [ -z "$VSC_PAT" ] ; then
      echo -e "❌ VSC PAT is not defined."
      exit 1
    fi

    RESPONSE_JSON=$(curl -u "$OWNER":"$VSC_PAT" -X GET https://marketplace.visualstudio.com/_apis/gallery/publishers/dennykorsukewitz/extensions/"$VSCODE_REPOSITORY"/stats)


    if [ -z "$RESPONSE_JSON" ] ; then
      echo -e "❌ No RESPONSE_JSON received."
      exit 1
    fi

    CURRENT_COUNT_INSTALL=$(echo "$CURRENT_JSON_TOTAL" | jq --arg REPOSITORY "$REPOSITORY" '[.[] | select(.[$REPOSITORY] != null)] | last | .[$REPOSITORY]' | sed 's/"//g')

    readarray -t STATS < <(echo "$RESPONSE_JSON" | jq --compact-output -r '.dailyStats |= sort_by(.statisticDate) | .dailyStats[]')

    for ROW in "${STATS[@]}"; do

      DATE=$(echo "$ROW" | jq '.statisticDate' | sed 's/\"//g')

      if [[ "$DATE" == "$TIMESTAMP" ]]; then

        COUNT_INSTALL=$(echo "$ROW" | jq '.counts.installCount' | sed 's/\"//g')

        REPOSITORYCOUNTER[$REPOSITORY]=$(( REPOSITORYCOUNTER[$REPOSITORY] + "$COUNT_INSTALL" ));

        COUNT_INSTALL_TOTAL=$(( REPOSITORYCOUNTER[$REPOSITORY] + "$CURRENT_COUNT_INSTALL" ));

        DATA_DAILY=$(
          echo "$DATA_DAILY" | jq ". + {\"date\": \"${DATE}\"}"
        )
        DATA_DAILY=$(
          echo "$DATA_DAILY" | jq ". + {\"$REPOSITORY\": \"${COUNT_INSTALL}\"}"
        )

        if [[ "$COUNT_INSTALL" == "null" || "$COUNT_INSTALL" == "0" ]]; then
          continue
        fi

        DATA_TOTAL=$(
          echo "$DATA_TOTAL" | jq ". + {\"date\": \"${DATE}\"}"
        )
        DATA_TOTAL=$(
          echo "$DATA_TOTAL" | jq ". + {\"$REPOSITORY\": \"${COUNT_INSTALL_TOTAL}\"}"
        )

        break
      fi
    done
done

JSON_TOTAL+=$DATA_TOTAL
JSON_TOTAL+=']'

JSON_DAILY+=$DATA_DAILY
JSON_DAILY+=']'

echo '------------------------------------'
for key in "${!REPOSITORYCOUNTER[@]}"
do
  echo "| ${key} => ${REPOSITORYCOUNTER[${key}]}"
done
echo '------------------------------------'

jq --argjson arr1 "$JSON_DAILY" --argjson arr2 "$CURRENT_JSON_DAILY" -n '$arr2 + $arr1 | sort_by(.date)' > ./.github/metrics/data/vscode-daily.json

jq --argjson arr1 "$JSON_TOTAL" --argjson arr2 "$CURRENT_JSON_TOTAL" -n '$arr2 + $arr1 | sort_by(.date)' > ./.github/metrics/data/vscode-total.json
