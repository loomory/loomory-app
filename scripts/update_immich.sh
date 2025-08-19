#!/bin/bash
set -e

if [ -z "$1" ]; then
  echo "Usage: $0 <version>"
  exit 1
fi
version="$1"

current_branch="$(git rev-parse --abbrev-ref HEAD)"
if [ "$current_branch" != "main" ]; then
  echo "Error: You must be on the 'main' branch to run this script. Current branch is '$current_branch'."
  exit 3
fi

if [ -n "$(git diff --cached --name-only | grep -v '^packages/immich')" ]; then
  echo "Error: You have other files staged for commit. Please unstage or push them before running this upgrade script."
  exit 4
fi

# Ensure submodule is initialized
git submodule update --init packages/immich

cd packages/immich
git fetch
git checkout "$version"
cd -

git add packages/immich
git commit -m "chore: update immich to $version"
git push origin main

echo "Immich submodule updated to $version."
echo "After pulling, other users should run: git submodule update --init packages/immich"
