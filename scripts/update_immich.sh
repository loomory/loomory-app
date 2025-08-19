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


# Update root pubspec.yaml version to match Immich Mobile
immich_version_line=$(grep '^version:' packages/immich/mobile/pubspec.yaml)
if [ -n "$immich_version_line" ]; then
  sed -i.bak "/^version:/c\\$immich_version_line" pubspec.yaml
  rm pubspec.yaml.bak
  echo "Root pubspec.yaml version updated to: $immich_version_line"
else
  echo "Warning: Could not find version line in packages/immich/mobile/pubspec.yaml"
fi

echo "Immich submodule updated to $version."
echo "After pulling, other users must run: git submodule update --init packages/immich"
echo "pubspec.yaml updated to $version. Do remember to review version breaking changes in copied files."

