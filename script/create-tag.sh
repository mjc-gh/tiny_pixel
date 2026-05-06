#!/bin/bash
# frozen_string_literal: true
# Script to create and push a new semantic version git tag

set -euo pipefail

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default to patch version increment
INCREMENT_TYPE="patch"

# Parse flags
while [[ $# -gt 0 ]]; do
  case $1 in
    --major)
      INCREMENT_TYPE="major"
      shift
      ;;
    --minor)
      INCREMENT_TYPE="minor"
      shift
      ;;
    --patch)
      INCREMENT_TYPE="patch"
      shift
      ;;
    *)
      echo -e "${RED}Unknown flag: $1${NC}"
      echo "Usage: ./scripts/create-tag.sh [--major|--minor|--patch]"
      exit 1
      ;;
  esac
done

# Get the latest tag, or default to v0.0.0 if none exist
LATEST_TAG=$(git tag -l 'v*' --sort=-version:refname | head -n 1)

if [ -z "$LATEST_TAG" ]; then
  LATEST_TAG="v0.0.0"
fi

# Parse version numbers
VERSION="${LATEST_TAG#v}"  # Remove 'v' prefix
IFS='.' read -r MAJOR MINOR PATCH <<< "$VERSION"

# Increment version based on type
case $INCREMENT_TYPE in
  major)
    MAJOR=$((MAJOR + 1))
    MINOR=0
    PATCH=0
    ;;
  minor)
    MINOR=$((MINOR + 1))
    PATCH=0
    ;;
  patch)
    PATCH=$((PATCH + 1))
    ;;
esac

# Create new tag
NEW_TAG="v${MAJOR}.${MINOR}.${PATCH}"

# Check if tag already exists
if git rev-parse "$NEW_TAG" >/dev/null 2>&1; then
  echo -e "${RED}Error: Tag $NEW_TAG already exists${NC}"
  exit 1
fi

# Create and push the tag
echo -e "${YELLOW}Creating tag: ${GREEN}$NEW_TAG${NC}"

if git tag -a "$NEW_TAG" -m "Release $NEW_TAG"; then
  echo -e "${GREEN}✓ Tag created locally${NC}"
else
  echo -e "${RED}✗ Failed to create tag${NC}"
  exit 1
fi

if git push origin "$NEW_TAG"; then
  echo -e "${GREEN}✓ Tag pushed to origin${NC}"
  echo -e "${GREEN}Successfully released $NEW_TAG${NC}"
else
  echo -e "${RED}✗ Failed to push tag${NC}"
  git tag -d "$NEW_TAG"
  exit 1
fi
