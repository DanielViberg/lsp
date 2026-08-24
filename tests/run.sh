#!/usr/bin/env bash
# Run the LSP test suite in a throwaway docker container:
# build the test image, run the tests in vim, and clean up afterwards.
set -uo pipefail

cd "$(dirname "$0")"

image="vim-lsp-image"

# Runs on every exit from the script (success, error or signal),
# so the test image is always removed - even when a command fails
# or the script is interrupted with Ctrl+C.
cleanup() {
  local rc=$?
  docker rmi -f "$image" >/dev/null 2>&1 || true
  exit "$rc"
}
trap cleanup EXIT
# On Ctrl+C / kill, exit through the normal exit path so the
# EXIT trap above also runs.
trap 'exit 130' INT
trap 'exit 143' TERM

# Build the test image; abort the script if the build fails.
docker build -t "$image" . || exit 1

# Run the tests in the foreground:
#   --rm  the container is removed automatically when vim exits
#   -it   keep the session interactive, so when a test fails vim is
#         left open on the failing buffer and you can debug/edit there
#   -v    mount the repo as /app and the test scratch dir as /tmp
# vim's exit code becomes this script's exit code.
docker run --rm -it -v "$(pwd)/../:/app" -v "$(pwd)/tmp:/tmp" "$image" \
  vim -u DEFAULTS -c "source /app/plugin/lsp.vim" -c "source /app/tests/run.vim"
