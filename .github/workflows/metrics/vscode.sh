#!/usr/bin/env bash

OWNER="dennykorsukewitz"

mapfile -t REPOSITORIES < <(gh search repos --owner "$OWNER" --topic "vsc" --jq '.[].name' --json name | sort)

declare -A REPOSITORYCOUNTER
JSON='['
COUNTER=0
for REPOSITORY in "${REPOSITORIES[@]}"; do
  echo -e "\n-----------$REPOSITORY-----------\n"

    VSCODE_REPOSITORY=${REPOSITORY//VSCode-/}

    if [ -z "$VSC_PAT" ] ; then
      echo -e "❌ VSC PAT is not defined."
      exit 1
    fi

    RESPONSE_JSON=$(curl -u "$OWNER":"$VSC_PAT" -X GET https://marketplace.visualstudio.com/_apis/gallery/publishers/dennykorsukewitz/extensions/"$VSCODE_REPOSITORY"/stats)
    # NAME=$(echo "$RESPONSE_JSON" | jq '.extensionName' | sed 's/\"//g')

    if [ -z "$RESPONSE_JSON" ] ; then
      echo -e "❌ No RESPONSE_JSON received."
      exit 1
    fi

    readarray -t STATS < <(echo "$RESPONSE_JSON" | jq --compact-output -r '.dailyStats |= sort_by(.statisticDate) | .dailyStats[]')

    if [ -z "$STATS" ] ; then
      echo -e "❌ No STATS."
      exit 1
    fi

    for ROW in "${STATS[@]}"; do

      DATE=$(echo "$ROW" | jq '.statisticDate' | sed 's/\"//g')
      COUNT_INSTALL=$(echo "$ROW" | jq '.counts.installCount' | sed 's/\"//g')

      if [[ "$COUNT_INSTALL" == "null" ]] ; then
        COUNT_INSTALL=0
        continue
      fi

      REPOSITORYCOUNTER[$REPOSITORY]=$(( REPOSITORYCOUNTER[$REPOSITORY] + "$COUNT_INSTALL" ));

      DATA=$(
        jq --null-input \
          --arg date "${DATE}" \
          --arg "$REPOSITORY" "${REPOSITORYCOUNTER[$REPOSITORY]}" \
          '$ARGS.named'
      )

      if [ ${COUNTER} != 0 ]; then
          JSON+=','
      fi

      JSON+=$DATA
      ((COUNTER+=1))
    done

done
JSON+=']'

echo '------------------------------------'
for key in "${!REPOSITORYCOUNTER[@]}"
do
  echo "| ${key} => ${REPOSITORYCOUNTER[${key}]}"
done
echo '------------------------------------'

echo "$JSON" > ./.github/metrics/data/vscode-data.json
jq '[ .[] ] | sort_by(.date) ' ./.github/metrics/data/vscode-data.json > ./.github/metrics/data/vscode.json

