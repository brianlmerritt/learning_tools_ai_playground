#!/usr/bin/env bash
# Runs one plugin's PHPUnit suite in separate test containers, never in the playground.
#
#   bin/plugin_phpunit.sh <plugin-dir> <moodle-path>
#
# <moodle-path> is where the plugin belongs in Moodle, for example
# local/rvc_enrolment_management. docker-compose.plugintest.yml copies core/moodle
# (mounted read-only) into its own volume, puts the plugin at <moodle-path>,
# initialises PHPUnit against its own PostgreSQL and runs the plugin's testsuite.
# The test containers are removed afterwards; the volumes are kept so later runs
# are faster. The first run, and any run after a version bump, rebuilds the
# PHPUnit site, which takes several minutes.
# Procedure: ~/.agents/skills/moodle-plugin-testing/SKILL.md

set -u

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
COMPOSE=(docker compose -p plugintest -f "$ROOT/docker-compose.plugintest.yml")

if [ $# -ne 2 ] || [ ! -f "$1/version.php" ]; then
    echo "Usage: $0 <plugin-dir> <moodle-path>" >&2
    exit 64
fi
PLUGIN="$(cd "$1" && pwd)"
MOODLEPATH="$2"
case "$MOODLEPATH" in
    /*|*..*|'') echo "The Moodle path must be relative, for example local/myplugin." >&2; exit 64 ;;
esac
COMPONENT="$(sed -n "s/^\$plugin->component *= *'\([a-z0-9_]*\)';.*/\1/p" "$PLUGIN/version.php")"
if [ -z "$COMPONENT" ]; then
    echo "No \$plugin->component found in $PLUGIN/version.php." >&2
    exit 65
fi

if ! docker info >/dev/null 2>&1; then
    echo "Docker is not running. Ask Brian to start Docker." >&2
    exit 69
fi

cleanup() {
    "${COMPOSE[@]}" down >/dev/null 2>&1
}
trap cleanup EXIT
trap 'exit 130' INT TERM

echo "Testing $COMPONENT from $PLUGIN at $MOODLEPATH (compose project plugintest)"
"${COMPOSE[@]}" up -d --wait db >/dev/null || exit 1

"${COMPOSE[@]}" run --rm -T \
    -v "$PLUGIN:/plugin:ro" \
    -e PLUGIN_PATH="$MOODLEPATH" \
    -e COMPONENT="$COMPONENT" \
    --entrypoint sh phpunit -c '
        set -e
        echo "Copying core/moodle into the test volume"
        find /var/www/html -mindepth 1 -delete
        cp -a /moodle-src/. /var/www/html/
        rm -rf "/var/www/html/$PLUGIN_PATH"
        mkdir -p "/var/www/html/$PLUGIN_PATH"
        cp -a /plugin/. "/var/www/html/$PLUGIN_PATH/"
        rm -rf "/var/www/html/$PLUGIN_PATH/.git"
        echo "Initialising PHPUnit (several minutes when the site must be rebuilt)"
        if ! php admin/tool/phpunit/cli/init.php > /tmp/init.log 2>&1; then
            tail -40 /tmp/init.log
            exit 1
        fi
        vendor/bin/phpunit --testsuite "${COMPONENT}_testsuite" --testdox
    '
