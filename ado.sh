ado() {
  if [ $# -eq 0 ]; then
    echo "pr      : Push the current branch, create a pull request, checkout master and delete the branch."
    echo "branch  : Create a new branch based on a task id an push it to origin."
  elif [ "$1" = pr ]; then
    createPullRequest "$@"
  elif [ "$1" = branch ]; then
    createBranchFromTaskId "$@"
  else
    echo "Command not recognized"
  fi
}

function createBranchFromTaskId() {
  shift
  if [ $# -eq 0 ]; then
    echo "ado branch <task id>"
  else
    local normalizedTaskName=$(\
      az boards work-item show \
      --id $1 | \
      jq -r '.fields["System.Title"]' | \
      sed 's/[^a-zA-Z0-9]/-/g')
    local branchName="$1-$normalizedTaskName"
    git checkout -b $branchName
    git push --set-upstream origin $branchName
  fi
}

function createPullRequest() {
  # Delete the first arg from $@
  shift
  local SOURCE_BRANCH=$(git rev-parse --abbrev-ref HEAD)
  local TASK_ID=$(echo $SOURCE_BRANCH | awk -F'-' '{print $1}')
  local params=()
  [[ $TASK_ID =~ '^[0-9]+$' ]] && params+=(--work-items $TASK_ID)
  git push
  az repos pr create \
    --open \
    --repository "$(basename `git config --get remote.origin.url`)" \
    --delete-source-branch true\
    --transition-work-items true \
    --source-branch "$SOURCE_BRANCH" \
    --output none \
    --title "$(git log -1 --pretty=format:%B)"
    "${params[@]}" \
    "$@"
  git checkout master
  git branch --delete "$SOURCE_BRANCH"
}

