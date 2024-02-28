#!/opt/homebrew/bin/bash

# ---
# Start Metrics
# ---
# /opt/homebrew/bin/bash .github/workflows/metrics/metrics.sh

# ---
# Step: Create github metrics
# ---
echo -e "\n-----------START github-----------\n"
/opt/homebrew/bin/bash .github/workflows/metrics/github.sh

# ---
# Step: Create daily metrics
# ---
echo -e "\n-----------START daily-----------\n"
/opt/homebrew/bin/bash .github/workflows/metrics/daily.sh

# ---
# Step: Create sublime metrics
# ---
echo -e "\n-----------START sublime-----------\n"
/opt/homebrew/bin/bash .github/workflows/metrics/sublime.sh

# ---
# Step: Create vscode metrics
# ---
echo -e "\n-----------START vscode-----------\n"
/opt/homebrew/bin/bash .github/workflows/metrics/vscode.sh

# ---
# Step: Create npm metrics
# ---
echo -e "\n-----------START npm-----------\n"
/opt/homebrew/bin/bash .github/workflows/metrics/npm.sh
