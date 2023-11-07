#!/usr/bin/env bash

OWNER="dennykorsukewitz"
REPOSITORIES=($(gh search repos --owner "dennykorsukewitz" --topic "vsc" --jq '.[].name' --json name | sort))

REPOSITORIES=('VSCode-Znuny')

# curl -L \
#  -X GET \
#  -H "Accept: Accept: application/json;api-version=3.0-preview.1" \
#  -H "Authorization: Bearer xxxx" \
#   https://marketplace.visualstudio.com/_apis/gallery/publishers/dennykorsukewitz/extensions/Znuny/stats

declare -A REPOSITORYCOUNTER

JSON='['
COUNTER=0
for REPOSITORY in "${REPOSITORIES[@]}"; do
  echo -e "\n-----------$REPOSITORY-----------\n"

    # STATSDATA=($(curl https://marketplace.visualstudio.com/_apis/gallery/publishers/dennykorsukewitz/extensions/Znuny/stats))


    STATS=($(cat ./.github/metrics/data/vscode-source.json | jq '.dailyStats'))

    for DATA in "${STATS[@]}"; do


      echo '---'
      echo $DATA
      echo '---'
    done


    # echo $(jq '.dailyStats' ./.github/metrics/data/vscode-source.json) > ./.github/metrics/data/vscode.json
    # echo $(jq '[.[] | .["date"] = .statisticDate | del(.statisticDate) ]' ./.github/metrics/data/vscode.json) > ./.github/metrics/data/vscode.json






    # for DATA in $(echo "$STATS" ); do
    # echo "$STATS" | jq '.dailyStats.[]' | while read -r repo; do
        # echo "---";
        # echo "do something with $DATA";
        # echo "---";


    #     if [ ${COUNTER} != 0 ]; then
    #         JSON+=','
    #     fi

    # #     REPOSITORYCOUNTER[Total]=$(( REPOSITORYCOUNTER[Total] + 1 ));
    # #     REPOSITORYCOUNTER[$REPOSITORY]=$(( REPOSITORYCOUNTER[$REPOSITORY] + 1 ));

    #     DATE=$(echo $ITEM | jq '.statisticDate' | sed 's/\"//g')
    #     COUNTS=$(echo $ITEM | jq '.counts' )

    #     echo ${DATE}
    #     echo ${COUNTS}

    #     DATA=$(
    #       jq --null-input \
    #         --arg date "${DATE}" \
    #         --arg total "${REPOSITORYCOUNTER[Total]}" \
    #         --arg ${COUNTS} \
    #         --arg $REPOSITORY "${REPOSITORYCOUNTER[$REPOSITORY]}" \
    #         '$ARGS.named'
    #     )

    #     JSON+=$DATA
    #     ((COUNTER+=1))

    # done
done
JSON+=']'

echo '------------------------------------'
for key in "${!REPOSITORYCOUNTER[@]}"
do
  echo "| ${key} \t \n \s => ${REPOSITORYCOUNTER[${key}]}"
done
echo '------------------------------------'

# echo $JSON > ./.github/metrics/data/vscode.json

# echo $(jq '[ .[] ] | sort_by(.date) | [ to_entries[]|.value.total=.key+1|.value ]' ./.github/metrics/data/vscode.json) > ./.github/metrics/data/vscode.json

