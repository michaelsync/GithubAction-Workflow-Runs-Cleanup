#!/bin/bash

# ==== CONFIGURATION ====
OWNER="your-github-username-or-org"
REPO="your-repo-name"
WORKFLOW_FILE="$1"             # Workflow file name (e.g., deploy.yml)
MAX_RUNS_TO_KEEP=1            # Keep the latest N runs
PER_PAGE=100
GITHUB_TOKEN="${GITHUB_TOKEN}" # Set as env var
# ========================

if [[ -z "$GITHUB_TOKEN" ]]; then
  echo "❌ GITHUB_TOKEN is not set. Please export it first."
  exit 1
fi

if [[ -z "$WORKFLOW_FILE" ]]; then
  echo "❌ Usage: $0 <workflow-file-name.yml>"
  exit 1
fi

# Get workflow IDs
# workflow_ids=$(curl -s -H "Authorization: Bearer $GITHUB_TOKEN" \
#   "https://api.github.com/repos/$OWNER/$REPO/actions/workflows" | jq -r '.workflows[].id')

# for workflow_id in $workflow_ids; do
#   echo "➡️  Processing Workflow ID: $workflow_id"

#   # Get all runs for the workflow
#   runs=$(curl -s -H "Authorization: Bearer $GITHUB_TOKEN" \
#     "https://api.github.com/repos/$OWNER/$REPO/actions/workflows/$workflow_id/runs?per_page=$PER_PAGE")

#   run_ids_to_delete=$(echo "$runs" | jq -r ".workflow_runs[$MAX_RUNS_TO_KEEP:] | .[].id")

#   for run_id in $run_ids_to_delete; do
#     echo "🗑️  Deleting run ID: $run_id"

#     curl -s -X DELETE -H "Authorization: Bearer $GITHUB_TOKEN" \
#       "https://api.github.com/repos/$OWNER/$REPO/actions/runs/$run_id"

#     sleep 1  # Optional: Avoid rate limits
#   done
# done

# Get workflow ID by file name
workflow_id=$(curl -s -H "Authorization: Bearer $GITHUB_TOKEN" \
  "https://api.github.com/repos/$OWNER/$REPO/actions/workflows" \
  | jq -r --arg wf "$WORKFLOW_FILE" '.workflows[] | select(.path | endswith($wf)) | .id')

if [[ -z "$workflow_id" ]]; then
  echo "❌ No workflow found for file: $WORKFLOW_FILE"
  exit 1
fi

echo "➡️  Found workflow ID: $workflow_id for file: $WORKFLOW_FILE"

# Get workflow runs
runs=$(curl -s -H "Authorization: Bearer $GITHUB_TOKEN" \
  "https://api.github.com/repos/$OWNER/$REPO/actions/workflows/$workflow_id/runs?per_page=$PER_PAGE")

# Get run IDs to delete
run_ids_to_delete=$(echo "$runs" | jq -r ".workflow_runs[$MAX_RUNS_TO_KEEP:] | .[].id")

if [[ -z "$run_ids_to_delete" ]]; then
  echo "✅ Nothing to delete. You have fewer than $MAX_RUNS_TO_KEEP runs."
  exit 0
fi

# Delete each run
for run_id in $run_ids_to_delete; do
  echo "🗑️  Deleting run ID: $run_id"
  curl -s -X DELETE -H "Authorization: Bearer $GITHUB_TOKEN" \
    "https://api.github.com/repos/$OWNER/$REPO/actions/runs/$run_id"
  sleep 1
done

echo "✅ Cleanup completed for $WORKFLOW_FILE"
