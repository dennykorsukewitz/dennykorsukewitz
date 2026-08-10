#!/bin/bash
set -euo pipefail

OWNER="dennykorsukewitz"
mapfile -t REPOSITORIES < <(gh search repos --owner "$OWNER" --jq '.[].name' --json name | sort)
if [ -z "${REPOSITORIES[0]:-}" ] ; then
  echo -e "❌ No REPOSITORIES received."
  exit 1
fi

# Stargazer timestamps require Accept: application/vnd.github.v3.star+json
# and a PAT that can read other repositories (GITHUB_TOKEN is repo-scoped and gets HTTP 403).

declare -A REPOSITORYCOUNTER
JSON='['
COUNTER=0
for REPOSITORY in "${REPOSITORIES[@]}"; do
  echo -e "\n-----------$REPOSITORY-----------"

  ERR_FILE="$(mktemp)"
  set +e
  STARGAZERS_JSON=$(
    gh api --paginate \
      -H "Accept: application/vnd.github.v3.star+json" \
      -H "X-GitHub-Api-Version: 2022-11-28" \
      "/repos/${OWNER}/${REPOSITORY}/stargazers" 2>"$ERR_FILE"
  )
  API_STATUS=$?
  set -e

  if [ "$API_STATUS" -ne 0 ]; then
    ERR_MSG=$(cat "$ERR_FILE")
    rm -f "$ERR_FILE"
    # Missing/private/renamed repos from search results: skip.
    if echo "$ERR_MSG" | grep -q 'HTTP 404'; then
      echo -e "⚠️  Skipping ${REPOSITORY} (not found)."
      continue
    fi
    # Auth/scope problems must fail the job (GITHUB_TOKEN causes HTTP 403).
    echo -e "❌ Failed to fetch stargazers for ${REPOSITORY}:"
    echo "$ERR_MSG"
    exit 1
  fi
  rm -f "$ERR_FILE"

  # Reject error payloads that slipped through without a non-zero exit.
  if echo "$STARGAZERS_JSON" | jq -e 'type == "object" and has("message")' >/dev/null; then
    echo -e "❌ GitHub API error for ${REPOSITORY}:"
    echo "$STARGAZERS_JSON" | jq -r '.message'
    exit 1
  fi

  STAR_COUNT=$(echo "$STARGAZERS_JSON" | jq 'if type == "array" then length else 0 end')
  if [ "$STAR_COUNT" -eq 0 ]; then
    continue
  fi

  while IFS= read -r STARGAZER; do
    REPOSITORYCOUNTER[$REPOSITORY]=$(( ${REPOSITORYCOUNTER[$REPOSITORY]:-0} + 1 ))

    DATE=$(echo "$STARGAZER" | jq -r '.starred_at // empty')
    USER=$(echo "$STARGAZER" | jq -r '.user.login // empty')

    if [ -z "$DATE" ] || [ -z "$USER" ]; then
      echo -e "❌ Invalid stargazer payload for ${REPOSITORY}: $STARGAZER"
      exit 1
    fi

    DATA=$(
      jq --null-input \
        --arg date "${DATE}" \
        --arg user "${USER}" \
        --arg "$REPOSITORY" "${REPOSITORYCOUNTER[$REPOSITORY]}" \
        '$ARGS.named'
    )

    if [ ${COUNTER} != 0 ]; then
      JSON+=','
    fi
    JSON+=$DATA
    COUNTER=$((COUNTER + 1))
  done < <(echo "$STARGAZERS_JSON" | jq -c '.[]')
done
JSON+=']'

echo '------------------------------------'
for key in "${!REPOSITORYCOUNTER[@]}"
do
  echo "| ${key} => ${REPOSITORYCOUNTER[${key}]}"
done
echo '------------------------------------'

echo "$JSON" | jq '[ .[] ] | sort_by(.date)' > ./.github/metrics/data/github-stars-data.json

jq '[ .[] ] | sort_by(.date) | [ to_entries[]|.value.total=.key+1|.value ]' ./.github/metrics/data/github-stars-data.json > ./.github/metrics/data/github-stars.json
