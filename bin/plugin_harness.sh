#!/usr/bin/env bash
# Runs a CLI harness against the running playground Moodle without installing anything.
#
#   bin/plugin_harness.sh <plugin-dir> <harness.php>
#
# The plugin folder and the harness are copied to a unique folder under the
# webserver container's /tmp, run there, and deleted afterwards, even on failure.
# The harness gets the copied plugin folder as its first argument. It must load
# /var/www/html/config.php, require the plugin's classes directly (the plugin is
# not installed) and roll back any database writes.
#
# Nothing is written to core/moodle, moodle-docker or the submodules. The script
# fails if core/moodle git status or the pending-upgrade state differ afterwards.
# Procedure: ~/.agents/skills/moodle-plugin-testing/SKILL.md

set -u

CONTAINER=moodle-docker-webserver-1
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MOODLE="$ROOT/core/moodle"

if [ $# -ne 2 ] || [ ! -d "$1" ] || [ ! -f "$2" ]; then
    echo "Usage: $0 <plugin-dir> <harness.php>" >&2
    exit 64
fi
PLUGIN="$(cd "$1" && pwd)"
HARNESS="$(cd "$(dirname "$2")" && pwd)/$(basename "$2")"

if ! docker info >/dev/null 2>&1; then
    echo "Docker is not running. Ask Brian to start Docker." >&2
    exit 69
fi
if [ "$(docker inspect -f '{{.State.Running}}' "$CONTAINER" 2>/dev/null)" != "true" ]; then
    echo "The playground is not running ($CONTAINER). Ask Brian to start it." >&2
    exit 69
fi

state() {
    git -C "$MOODLE" status --porcelain
    docker exec -w /var/www/html "$CONTAINER" php admin/cli/upgrade.php --is-pending >/dev/null 2>&1
    echo "upgrade-pending-exit=$?"
}

BEFORE="$(state)"
WORK="/tmp/plugin_harness.$(date +%Y%m%d%H%M%S).$$"
cleanup() {
    docker exec "$CONTAINER" rm -rf "$WORK"
}
trap cleanup EXIT
trap 'exit 130' INT TERM

docker exec "$CONTAINER" mkdir -p "$WORK"
docker cp -q "$PLUGIN" "$CONTAINER:$WORK/plugin"
docker exec "$CONTAINER" rm -rf "$WORK/plugin/.git"
docker cp -q "$HARNESS" "$CONTAINER:$WORK/harness.php"

echo "Harness folder: $CONTAINER:$WORK (removed at exit)"
docker exec -w /var/www/html "$CONTAINER" php "$WORK/harness.php" "$WORK/plugin"
RESULT=$?

AFTER="$(state)"
if [ "$BEFORE" != "$AFTER" ]; then
    echo "FAIL: core/moodle git status or the pending-upgrade state changed during the run." >&2
    diff <(echo "$BEFORE") <(echo "$AFTER") >&2
    exit 1
fi
echo "Playground unchanged: core/moodle git status and pending-upgrade state match."
echo "Harness exit code: $RESULT"
exit $RESULT
