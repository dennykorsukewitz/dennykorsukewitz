#!/bin/bash
# /opt/homebrew/bin/bash .github/scripts/github-webhooks.sh

OWNER="dennykorsukewitz"
REPOSITORY="dennykorsukewitz"
mapfile -t REPOSITORIES < <(gh search repos --owner "$OWNER" --topic "pages" --jq '.[].name' --json name | sort)
REPOSITORIES+=("DK4")
REPOSITORIES+=("dennykorsukewitz.github.io")
REPOSITORIES+=("dennykorsukewitz")

# DISCORD_WEBHOOK_ANY
# DISCORD_WEBHOOK_STARS
# DISCORD_WEBHOOK_RELEASE

for REPOSITORY in "${REPOSITORIES[@]}"; do

    echo -e "\n-----------$REPOSITORY-----------\n"

    for ID in $(gh api repos/"$OWNER"/"$REPOSITORY"/hooks -q '.[].id'); do
        gh api -X DELETE repos/"$OWNER"/"$REPOSITORY"/hooks/"$ID"  > /dev/null 2>&1
    done

    echo "all"
    RESPONSE=$(gh api -X POST repos/"$OWNER"/"$REPOSITORY"/hooks --input <(cat <<< "{
    'name': 'web',
    'active': true,
    'events': [
        'branch_protection_configuration',
        'branch_protection_rule',
        'check_run',
        'check_suite',
        'code_scanning_alert',
        'commit_comment',
        'create',
        'custom_property_values',
        'delete',
        'dependabot_alert',
        'deploy_key',
        'deployment',
        'deployment_status',
        'discussion',
        'discussion_comment',
        'fork',
        'gollum',
        'issue_comment',
        'issues',
        'label',
        'member',
        'merge_group',
        'meta',
        'milestone',
        'package',
        'page_build',
        'ping',
        'project_card',
        'project',
        'project_column',
        'public',
        'pull_request',
        'pull_request_review_comment',
        'pull_request_review',
        'pull_request_review_thread',
        'push',
        'registry_package',
        'repository_advisory',
        'repository',
        'repository_import',
        'repository_ruleset',
        'repository_vulnerability_alert',
        'secret_scanning_alert',
        'secret_scanning_alert_location',
        'security_and_analysis',
        'status',
        'team_add',
        'watch',
        'workflow_job',
        'workflow_run'
    ],
    'config': {
        'url': '${{ secrets.DISCORD_WEBHOOK_ANY }}',
        'content_type': 'json'
    }
}")) > /dev/null 2>&1

    echo "star"
    RESPONSE=$(gh api -X POST repos/"$OWNER"/"$REPOSITORY"/hooks --input <(cat <<< "{
        'name': 'web',
        'active': true,
        'events': ['star', 'watch'],
        'config': {
            'url': '${{ secrets.DISCORD_WEBHOOK_STAR }}': 'json'
        }
    }")) > /dev/null 2>&1

    echo "release"
    RESPONSE=$(gh api -X POST repos/"$OWNER"/"$REPOSITORY"/hooks --input <(cat <<< "{
        'name': 'web',
        'active': true,
        'events': ['release'],
        'config': {
            'url': '${{ secrets.DISCORD_WEDISCORD_WEBHOOK_RELEASEBHOOK_STAR }}',
            'content_type': 'json'
        }
    }")) > /dev/null 2>&1

    echo "$RESPONSE"

done
