#!/usr/bin/env bash

set -e

source test/setup

use Test::More

export round=0
test_round() {
  clone-foo-and-bar

  touch ~/x
  echo "=================================================" >> ~/x
  round=$(( round + 1 ))
  normalize_dir=$1
  echo $normalize_dir >> ~/x
  normalize_dir=${normalize_dir#./}
  echo $normalize_dir >> ~/x
  normalize_dir=${normalize_dir%/}
  echo $normalize_dir >> ~/x
  while [[ $normalize_dir =~ (//+) ]]; do normalize_dir=${normalize_dir//${BASH_REMATCH[1]}/\/}; done
  echo $normalize_dir >> ~/x

  clone_output=$(
    cd "$OWNER/foo"
    echo "git subrepo clone $UPSTREAM/bar -- $normalize_dir" >> ~/x
    git subrepo clone "$UPSTREAM/bar" -- "$normalize_dir"
  )

  # Check output is correct:
  is "$clone_output" \
    "Subrepo '$UPSTREAM/bar' (master) cloned into '$normalize_dir'." \
    'subrepo clone command output is correct'

  test-exists "$OWNER/foo/$normalize_dir/"

  (
    cd "$OWNER/bar"
    git pull
    add-new-files Bar2-$round
    git push
  ) &> /dev/null || die

  # Do the pull and check output:
  {
    is "$(
       cd "$OWNER/foo"
       echo "git subrepo pull -- $normalize_dir" >> ~/x
       git subrepo pull -- "$normalize_dir"
       )" \
       "Subrepo '$normalize_dir' pulled from '$UPSTREAM/bar' (master)." \
       'subrepo pull command output is correct'
  }

  test-exists "$OWNER/foo/$normalize_dir/"

  (
    cd "$OWNER/foo/$normalize_dir"
    git pull
    add-new-files new-$round
    git push
  ) &> /dev/null || die

  # Do the push and check output:
  {
    is "$(
       cd "$OWNER/foo"
       echo "git subrepo push -- $normalize_dir" >> ~/x
       git subrepo push -- "$normalize_dir"
       )" \
       "Subrepo '$normalize_dir' pushed to '$UPSTREAM/bar' (master)." \
       'subrepo push command output is correct'
  }
}

test_round ~'////......s:a^t?r a*n[g@{e.lock'


done_testing

teardown
