#!/usr/bin/env bash

OWNER="dennykorsukewitz"
PAT=hd4odfa2vbmztshgn5vaccrixp7brnfli5u7hmh5xvnovlqhucrq

mapfile -t REPOSITORIES < <(gh search repos --owner "$OWNER" --topic "vsc" --jq '.[].name' --json name | sort)

REPOSITORIES=('VSCode-Znuny')

declare -A REPOSITORYCOUNTER

JSON='['
COUNTER=0
for REPOSITORY in "${REPOSITORIES[@]}"; do
  echo -e "\n-----------$REPOSITORY-----------\n"

    VSCODE_REPOSITORY=$(echo $REPOSITORY | sed 's/VSCode-//g')

    # STATSDATA=($(curl https://marketplace.visualstudio.com/_apis/gallery/publishers/dennykorsukewitz/extensions/Znuny/stats))

    echo $VSCODE_REPOSITORY
    echo $PAT

    JSON=$(curl -u "$OWNER":"$PAT" -X GET https://marketplace.visualstudio.com/_apis/gallery/publishers/dennykorsukewitz/extensions/$VSCODE_REPOSITORY/stats)

    NAME=$(echo "$JSON" | jq '.extensionName' | sed 's/\"//g')
    mapfile -t STATS < <(echo "$JSON" | jq .dailyStats)


    echo "NAME"
    echo $NAME
    echo "STATS"
    echo $STATS

    # STATS=("$(cat ./.github/metrics/data/vscode-data.json | jq '.dailyStats')")

    for DATA in "${STATS[@]}"; do


      echo '---'
      echo $DATA
      echo '---'
    done

done
JSON+=']'

echo '------------------------------------'
for key in "${!REPOSITORYCOUNTER[@]}"
do
  echo "| ${key} \t \n \s => ${REPOSITORYCOUNTER[${key}]}"
done
echo '------------------------------------'

# echo $JSON > ./.github/metrics/data/vscode-data.json

# jq '[ .[] ] | sort_by(.date) | [ to_entries[]|.value.total=.key+1|.value ]' ./.github/metrics/data/vscode-data.json > ./.github/metrics/data/vscode.json

