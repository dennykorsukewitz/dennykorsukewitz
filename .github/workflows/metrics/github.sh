#!/usr/bin/env bash

OWNER="dennykorsukewitz"
REPOSITORIES=($(gh search repos --owner "dennykorsukewitz" --jq '.[].name' --json name | sort))

# curl -L \
#   -H "Accept: Accept: application/vnd.github.v3.star+json" \
#   -H "Authorization: Bearer TOKEN" \
#   -H "X-GitHub-Api-Version: 2022-11-28" \
#   https://api.github.com/repos/dennykorsukewitz/vscode-znuny/stargazers

declare -A REPOSITORYCOUNTER
REPOSITORYCOUNTER['Total']=0;

JSON='['
COUNTER=0
for REPOSITORY in "${REPOSITORIES[@]}"; do
  echo -e "\n-----------$REPOSITORY-----------\n"
    STARGAZERS=($(gh api -H "Accept: application/vnd.github.v3.star+json" -H "X-GitHub-Api-Version: 2022-11-28" /repos/$OWNER/$REPOSITORY/stargazers --jq '.[]'))

    for STARGAZER in "${STARGAZERS[@]}"; do

        if [ ${COUNTER} != 0 ]; then
            JSON+=','
        fi

        REPOSITORYCOUNTER[Total]=$(( REPOSITORYCOUNTER[Total] + 1 ));
        REPOSITORYCOUNTER[$REPOSITORY]=$(( REPOSITORYCOUNTER[$REPOSITORY] + 1 ));

        DATE=$(echo $STARGAZER | jq '.starred_at' | sed 's/\"//g')
        USER=$(echo $STARGAZER | jq '.user.login' | sed 's/\"//g')

        DATA=$(
          jq --null-input \
            --arg date "${DATE}" \
            --arg total "${REPOSITORYCOUNTER[Total]}" \
            --arg user "${USER}" \
            --arg $REPOSITORY "${REPOSITORYCOUNTER[$REPOSITORY]}" \
            '$ARGS.named'
        )

        JSON+=$DATA
        ((COUNTER+=1))

    done
done
JSON+=']'

echo '------------------------------------'
for key in ${!REPOSITORYCOUNTER[@]}
do
  echo "| ${key} \t \n \s => ${REPOSITORYCOUNTER[${key}]}"
done
echo '------------------------------------'

echo $JSON > ./.github/metrics/data/github-stars.json
