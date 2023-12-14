#!/usr/bin/env bash

OWNER="dennykorsukewitz"

# https://packagecontrol.io/packages/"$SUBLIME_REPOSITORY".json
mapfile -t REPOSITORIES < <(gh search repos --owner "$OWNER" --topic "metrics-sublime" --jq '.[].name' --json name | sort)

declare -A REPOSITORYCOUNTER
JSON='['
JSON_DAILY=''
COUNTER=0
COUNT_INSTALL_TOTAL=0
CURRENT_JSON=$(jq . ./.github/metrics/data/sublime.json)

for REPOSITORY in "${REPOSITORIES[@]}"; do
  echo -e "\n-----------$REPOSITORY-----------\n"

    SUBLIME_REPOSITORY=${REPOSITORY//Sublime-/}
    SUBLIME_REPOSITORY=$(echo "$SUBLIME_REPOSITORY" | sed 's/[A-Z]/ &/g' | xargs | sed 's/Git Hub/GitHub/g' | sed 's/ /%20/g')

    RESPONSE_JSON=$(curl https://packagecontrol.io/packages/"$SUBLIME_REPOSITORY".json)

    if [ -z "$RESPONSE_JSON" ] ; then
      echo -e "❌ No RESPONSE_JSON received."
      exit 1
    fi

    DATE=$(echo "$RESPONSE_JSON" | jq --compact-output -r ".installs.daily.dates[1]")
    CURRENT_COUNT_INSTALL=$(echo "$CURRENT_JSON" | jq --arg REPOSITORY "$REPOSITORY" '.[-1] | .[$REPOSITORY]'  | sed 's/"//g')

    COUNT_INSTALL=0
    for i in {0..2}
    do
      COUNT_INSTALL=$(echo "$RESPONSE_JSON" | jq --compact-output -r ".installs.daily.data[$i].totals[1]")
      REPOSITORYCOUNTER[$REPOSITORY]=$(( REPOSITORYCOUNTER[$REPOSITORY] + "$COUNT_INSTALL" ));
    done

    COUNT_INSTALL_TOTAL=$(( REPOSITORYCOUNTER[$REPOSITORY] + "$CURRENT_COUNT_INSTALL" ));

    DATA=$(
      jq --null-input \
        --arg date "${DATE}" \
        --arg "$REPOSITORY" "${COUNT_INSTALL_TOTAL}" \
        '$ARGS.named'
    )

    DAILY_DATA=$(
      jq --null-input \
        --arg date "${DATE}" \
        --arg "$REPOSITORY" "${REPOSITORYCOUNTER[$REPOSITORY]}" \
        '$ARGS.named'
    )

    if [ ${COUNTER} != 0 ]; then
        JSON+=','
    fi

    JSON+=$DATA
    JSON_DAILY+=$DAILY_DATA
    ((COUNTER+=1))

done
JSON+=']'

echo '------------------------------------'
for key in "${!REPOSITORYCOUNTER[@]}"
do
  echo "| ${key} => ${REPOSITORYCOUNTER[${key}]}"
done
echo '------------------------------------'


echo "$JSON_DAILY" | jq --compact-output >> ./.github/metrics/data/sublime-data.json
jq --argjson arr1 "$JSON" --argjson arr2 "$CURRENT_JSON" -n '$arr2 + $arr1 | sort_by(.date)' > ./.github/metrics/data/sublime.json

