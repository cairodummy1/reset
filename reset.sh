#!/bin/bash

# Function to handle errors
error_handler() {
    echo "ERROR: Command failed with exit code $?"
    echo "Last command: $BASH_COMMAND"
    exit 1
}

# Set error handling
set -e
trap error_handler ERR

# Configuration
REPO_OWNER="theniceduck"
REPO_NAME="jetson-training"
REPO_URL="https://github.com/${REPO_OWNER}/${REPO_NAME}.git"
DATA_DIR="/home/jetson-gmi/jetson-training/data"

echo "[STEP 0] Checking if repository is public..."
API_URL="https://api.github.com/repos/${REPO_OWNER}/${REPO_NAME}"
HTTP_CODE=$(curl -sS -H "Accept: application/vnd.github+json" -H "User-Agent: repo-check-script" -o /tmp/repo_meta.json -w "%{http_code}" "$API_URL" || true)
if [ "$HTTP_CODE" != "200" ]; then
    echo "ERROR: Repository is not publicly accessible (HTTP $HTTP_CODE). Make it public and try again."
    exit 1
fi
if grep -q '"private"[[:space:]]*:[[:space:]]*true' /tmp/repo_meta.json; then
    echo "ERROR: Repository is private. Make it public and try again."
    exit 1
fi

echo "[STEP 1] Cleaning data directory..."
sudo rm -rf "$DATA_DIR"/{*,.[!.]*,..?*}

echo "[STEP 2] Cloning fresh repo..."
if ! git clone "$REPO_URL" "$DATA_DIR" 2>&1; then
    echo "ERROR: Failed to clone repository. This could be because:"
    echo "1. Network connectivity issues"
    echo "2. GitHub outage or rate limiting"
    exit 1
fi

cd "$DATA_DIR"

echo "[STEP 3] Removing .git and .gitignore..."
sudo rm -rf .git .gitignore

echo "[STEP 4] Combining part files..."
python3 combine/combine.py "/home/jetson-gmi/jetson-training/data/4. Object Detection/"
python3 combine/combine.py "/home/jetson-gmi/jetson-training/data/5. Segmentation/"
python3 combine/combine.py "/home/jetson-gmi/jetson-training/data/Aux 3. Real Time Detection/"

echo "[STEP 5] Removing combine/ folder and reset.sh"
sudo rm -rf combine/

echo "[ALL DONE] Workflow completed successfully."

