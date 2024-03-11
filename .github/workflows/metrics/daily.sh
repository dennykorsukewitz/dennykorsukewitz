#!/bin/bash

jq -s '[.[] | .[]] | group_by(.date) | map(add)' .github/metrics/data/sublime-daily.json .github/metrics/data/vscode-daily.json .github/metrics/data/npm-daily.json > .github/metrics/data/daily.json