#!/bin/bash
# /opt/homebrew/bin/bash .github/scripts/github-webhooks.sh

OWNER="dennykorsukewitz"
REPOSITORY="dennykorsukewitz"
mapfile -t REPOSITORIES < <(gh search repos --owner "$OWNER" --topic "pages" --jq '.[].name' --json name | sort)
REPOSITORIES+=("DK4")
REPOSITORIES+=("dennykorsukewitz.github.io")
REPOSITORIES+=("dennykorsukewitz")

# ANY https://discord.com/api/webhooks/1157760136438362123/VqZ93Um98Bw5CSL9gAbNy662Ao0h6PDHfXJABahC6vtAB2DIuCSQevZojxNXfyATAMJj/github
# RELEASE https://discord.com/api/webhooks/1204360397554196500/uPegYZU5Di-90wtise5Qk4gclQFcc7Py3iTNTYd7GHf1UAgV1-_5QsG-Z6TF762nrlqO/github
# STARS https://discord.com/api/webhooks/1204335792030228502/JMLHlmX-EdX-V1SBQpE745GsJfRES2nFVAKYO7R9Hp64bhPR4vTZ58ocfqxeMJdFkEnu/github

for REPOSITORY in "${REPOSITORIES[@]}"; do

    echo -e "\n-----------$REPOSITORY-----------\n"

    for id in $(gh api repos/$OWNER/$REPOSITORY/hooks -q '.[].id'); do
        gh api -X DELETE repos/$OWNER/$REPOSITORY/hooks/$id  > /dev/null 2>&1
    done

    echo "all"
    response=$(gh api -X POST repos/$OWNER/$REPOSITORY/hooks --input <(cat <<< '{
    "name": "web",
    "active": true,
    "events": [
        "branch_protection_configuration",
        "branch_protection_rule",
        "check_run",
        "check_suite",
        "code_scanning_alert",
        "commit_comment",
        "create",
        "custom_property_values",
        "delete",
        "dependabot_alert",
        "deploy_key",
        "deployment",
        "deployment_status",
        "discussion",
        "discussion_comment",
        "fork",
        "gollum",
        "issue_comment",
        "issues",
        "label",
        "member",
        "merge_group",
        "meta",
        "milestone",
        "package",
        "page_build",
        "ping",
        "project_card",
        "project",
        "project_column",
        "public",
        "pull_request",
        "pull_request_review_comment",
        "pull_request_review",
        "pull_request_review_thread",
        "push",
        "registry_package",
        "repository_advisory",
        "repository",
        "repository_import",
        "repository_ruleset",
        "repository_vulnerability_alert",
        "secret_scanning_alert",
        "secret_scanning_alert_location",
        "security_and_analysis",
        "status",
        "team_add",
        "watch",
        "workflow_job",
        "workflow_run"
    ],
    "config": {
        "url": "https://discord.com/api/webhooks/1157760136438362123/VqZ93Um98Bw5CSL9gAbNy662Ao0h6PDHfXJABahC6vtAB2DIuCSQevZojxNXfyATAMJj/github",
        "content_type": "json"
    }
}')) > /dev/null 2>&1


    echo "star"
    response=$(gh api -X POST repos/$OWNER/$REPOSITORY/hooks --input <(cat <<< '{
        "name": "web",
        "active": true,
        "events": ["star", "watch"],
        "config": {
            "url": "https://discord.com/api/webhooks/1204335792030228502/JMLHlmX-EdX-V1SBQpE745GsJfRES2nFVAKYO7R9Hp64bhPR4vTZ58ocfqxeMJdFkEnu/github",
            "content_type": "json"
        }
    }')) > /dev/null 2>&1

    echo "release"
    response=$(gh api -X POST repos/$OWNER/$REPOSITORY/hooks --input <(cat <<< '{
        "name": "web",
        "active": true,
        "events": ["release"],
        "config": {
            "url": "https://discord.com/api/webhooks/1204360397554196500/uPegYZU5Di-90wtise5Qk4gclQFcc7Py3iTNTYd7GHf1UAgV1-_5QsG-Z6TF762nrlqO/github",
            "content_type": "json"
        }
    }')) > /dev/null 2>&1

done
