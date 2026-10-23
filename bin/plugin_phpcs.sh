#!/usr/bin/env bash
# Runs Moodle's code-style check (moodle-cs) on one plugin in a separate container.
#
#   bin/plugin_phpcs.sh <plugin-dir> [--fix]
#
# This is the plugins' CI check: phpcs --standard=moodle, failing on any error or
# warning. --fix first runs phpcbf, which corrects the auto-fixable problems in
# <plugin-dir> itself; nothing else is written. moodle-cs is installed into the
# kept volume plugintest_phpcstools on the first run, which needs internet access.
# The container is removed afterwards.
# Procedure: ~/.agents/skills/moodle-plugin-testing/SKILL.md

set -u

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
COMPOSE=(docker compose -p plugintest -f "$ROOT/docker-compose.plugintest.yml")

if [ $# -lt 1 ] || [ $# -gt 2 ] || [ ! -f "$1/version.php" ] || { [ $# -eq 2 ] && [ "$2" != "--fix" ]; }; then
    echo "Usage: $0 <plugin-dir> [--fix]" >&2
    exit 64
fi
PLUGIN="$(cd "$1" && pwd)"
FIX=0
MODE=ro
if [ $# -eq 2 ]; then
    FIX=1
    MODE=rw
fi

if ! docker info >/dev/null 2>&1; then
    echo "Docker is not running. Ask Brian to start Docker." >&2
    exit 69
fi

echo "Code-style check of $PLUGIN (fix: $FIX)"
"${COMPOSE[@]}" run --rm -T \
    -v "$PLUGIN:/plugin:$MODE" \
    -e FIX="$FIX" \
    --entrypoint sh phpcs -c '
        set -e
        BIN=/opt/phpcs/vendor/bin
        if [ ! -x "$BIN/phpcs" ]; then
            echo "Installing moodle-cs into the phpcstools volume (first run only)"
            cd /opt/phpcs
            php -r "copy(\"https://getcomposer.org/download/latest-stable/composer.phar\", \"composer.phar\");"
            php -r "copy(\"https://getcomposer.org/download/latest-stable/composer.phar.sha256sum\", \"composer.phar.sha256sum\");"
            sha256sum -c composer.phar.sha256sum
            php composer.phar global config --no-interaction allow-plugins.dealerdirect/phpcodesniffer-composer-installer true
            php composer.phar global require --no-interaction --quiet moodlehq/moodle-cs
        fi
        if [ "$FIX" = 1 ]; then
            "$BIN/phpcbf" --standard=moodle --extensions=php /plugin || true
        fi
        "$BIN/phpcs" --standard=moodle --extensions=php --report-width=120 /plugin
        echo "Code-style check passed: no errors or warnings."
    '
