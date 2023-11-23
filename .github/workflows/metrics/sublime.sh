#!/usr/bin/env bash

OWNER="dennykorsukewitz"

# https://packagecontrol.io/packages/"$SUBLIME_REPOSITORY".json
mapfile -t REPOSITORIES < <(gh search repos --owner "$OWNER" --topic "sublime-package" --jq '.[].name' --json name | sort)

REPOSITORIES=('Sublime-QuoteWithMarker')

declare -A REPOSITORYCOUNTER
JSON='['
JSON_DATA=''
COUNTER=0
for REPOSITORY in "${REPOSITORIES[@]}"; do
  echo -e "\n-----------$REPOSITORY-----------\n"

    SUBLIME_REPOSITORY=${REPOSITORY//Sublime-/}
    SUBLIME_REPOSITORY=$(echo $SUBLIME_REPOSITORY | sed 's/[A-Z]/ &/g' | xargs | sed 's/Git Hub/GitHub/g' | sed 's/ /%20/g')

    RESPONSE_JSON=$(curl https://packagecontrol.io/packages/"$SUBLIME_REPOSITORY".json)

    if [ -z "$RESPONSE_JSON" ] ; then
      echo -e "❌ No RESPONSE_JSON received."
      exit 1
    fi

    readarray -t DATES < <(echo "$RESPONSE_JSON" | jq --compact-output -r '.installs.daily.dates')
    DATE=$(echo "$RESPONSE_JSON" | jq --compact-output -r ".installs.daily.dates[1]")

    COUNT_INSTALL=0
    for i in {0..2}
    do
      COUNT_INSTALL=$(echo "$RESPONSE_JSON" | jq --compact-output -r ".installs.daily.data[$i].totals[1]")
      REPOSITORYCOUNTER[$REPOSITORY]=$(( REPOSITORYCOUNTER[$REPOSITORY] + "$COUNT_INSTALL" ));
    done

    DATA=$(
      jq --null-input \
        --arg date "${DATE}" \
        --arg "$REPOSITORY" "${REPOSITORYCOUNTER[$REPOSITORY]}" \
        '$ARGS.named'
    )

    echo $DATA

    if [ ${COUNTER} != 0 ]; then
        JSON+=','
    fi

    JSON+=$DATA
    JSON_DATA+=$DATA
    ((COUNTER+=1))

done
JSON+=']'

echo '------------------------------------'
for key in "${!REPOSITORYCOUNTER[@]}"
do
  echo "| ${key} => ${REPOSITORYCOUNTER[${key}]}"
done
echo '------------------------------------'

CURRENT_JSON=$(cat ./.github/metrics/data/sublime.json | jq)

echo "$JSON_DATA" | jq --compact-output >> ./.github/metrics/data/sublime-data.json
jq --argjson arr1 "$JSON" --argjson arr2 "$CURRENT_JSON" -n '$arr2 + $arr1 | sort_by(.date)' > ./.github/metrics/data/sublime.json

