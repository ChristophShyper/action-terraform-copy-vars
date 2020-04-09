#!/usr/bin/env bash

set -e

# github_token required
if [[ -z "${INPUT_GITHUB_TOKEN}" && ${INPUT_PUSH_CHANGES} == "true" ]]; then
  MESSAGE='Missing variable "github_token: ${{ secrets.GITHUB_TOKEN }}".'
  echo ${MESSAGE}
  echo "::error ${MESSAGE}"
  exit 1
fi

# Run main action
python /terraform-copy-variables.py
RET_CODE=$?

# List of changed files
FILES_CHANGED=$(git diff --name-only)

# Get the name of the current branch
BRANCH=${GITHUB_REF/refs\/heads\//}

# Info about formatted files
if [[ ! -z ${FILES_CHANGED} ]]; then
  echo "[INFO] Updated files:"
  for FILE in ${FILES_CHANGED}; do
    echo "- ${FILE}"
  done
else
  echo "[INFO] No files updated."
fi

# Create auto commit
if [[ ${INPUT_PUSH_CHANGES} == "true" && ! -z ${FILES_CHANGED} ]]; then
  # Create auto commit
  echo " "
  REPO_URL="https://${GITHUB_ACTOR}:${INPUT_GITHUB_TOKEN}@github.com/${GITHUB_REPOSITORY}.git"
  git config --global user.name ${GITHUB_ACTOR}
  git config --global user.email ${GITHUB_ACTOR}@users.noreply.github.com
  git commit -am "[AUTO] ${MESSAGE}"
  git push ${REPO_URL} HEAD:${BRANCH}
  echo " "
  echo "::set-output name=files_changed::${FILES_CHANGED}"
  echo " "
  exit 0
fi

# Fail if needed
if [[ ${INPUT_FAIL_ON_MISSING} == "true" && ${RET_CODE} != "0" ]]; then
  echo " "
  echo "::set-output name=files_changed::${FILES_CHANGED}"
  echo " "
  exit 1
else
  # Pass in other cases
  echo " "
  echo "::set-output name=files_changed::${FILES_CHANGED}"
  echo " "
  exit 0
fi
