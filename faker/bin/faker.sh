#!/usr/bin/env bash
# Fictional test data for the playground. Plan: faker/project.md; usage: faker/README.md.
#
#   faker/bin/faker.sh up <dataset>        generate, feed, moodle, sync, after, status
#   faker/bin/faker.sh generate <dataset>  build data/<dataset>.* in the faker container
#   faker/bin/faker.sh feed <dataset>      create the feed databases if missing; load the feed
#   faker/bin/faker.sh moodle <dataset>    create courses and people; configure enrol_database
#   faker/bin/faker.sh sync                run the enrol_database sync task
#   faker/bin/faker.sh after <dataset>     apply the after-sync changes (leavers and others)
#   faker/bin/faker.sh reset               delete faker data, empty the feed databases,
#                                          restore enrol_database settings
#   faker/bin/faker.sh status              read-only counts
#
# Never writes to core/moodle files or git. Moodle-side scripts run from the webserver
# container's /tmp and are removed afterwards.

set -u

FAKER="$(cd "$(dirname "$0")/.." && pwd)"
DATA="$FAKER/data"
WEB=moodle-docker-webserver-1
DB=moodle-docker-db-1
COMPOSE=(docker compose -p faker -f "$FAKER/docker-compose.faker.yml")
FEEDDBS="database_enrol database_extended_enrol"
WORK=""

die() {
    echo "$1" >&2
    exit "${2:-1}"
}

need_docker() {
    docker info >/dev/null 2>&1 || die "Docker is not running. Ask Brian to start Docker." 69
}

need_playground() {
    need_docker
    for container in "$WEB" "$DB"; do
        [ "$(docker inspect -f '{{.State.Running}}' "$container" 2>/dev/null)" = "true" ] ||
            die "The playground is not running ($container). Ask Brian to start it." 69
    done
}

need_dataset() {
    [ -n "${1:-}" ] && [ -f "$FAKER/config/$1.php" ] || die "Unknown data set '${1:-}'; see faker/config/." 64
}

need_generated() {
    [ -f "$DATA/$1.json" ] || die "No data/$1.json yet; run: faker/bin/faker.sh generate $1" 65
}

psql_db() {
    docker exec -i "$DB" psql -v ON_ERROR_STOP=1 -q -U moodle -d "$@"
}

cleanup() {
    if [ -n "$WORK" ]; then
        docker exec "$WEB" rm -rf "$WORK"
    fi
}
trap cleanup EXIT
trap 'exit 130' INT TERM

# Runs one moodle/ script in the webserver container, with a copy of data/ beside it.
in_web() {
    local script="$1"
    shift
    if [ -z "$WORK" ]; then
        WORK="/tmp/faker.$(date +%Y%m%d%H%M%S).$$"
        docker exec "$WEB" mkdir -p "$WORK/data"
    fi
    docker cp -q "$FAKER/moodle/." "$WEB:$WORK/"
    [ -d "$DATA" ] && docker cp -q "$DATA/." "$WEB:$WORK/data/"
    docker exec -w /var/www/html "$WEB" php "$WORK/$script" "$WORK/data" "$@" || die "moodle/$script failed."
}

cmd_generate() {
    need_dataset "${1:-}"
    need_docker
    "${COMPOSE[@]}" run --rm -T --entrypoint sh faker -c '
        set -e
        if [ ! -f vendor/autoload.php ]; then
            echo "Installing fakerphp/faker into the faker vendor volume (first run only)"
            php -r "copy(\"https://getcomposer.org/download/latest-stable/composer.phar\", \"vendor/composer.phar\");"
            php vendor/composer.phar update --no-interaction --quiet
        fi
        php bin/generate.php "$0"
    ' "$1" || die "Generation failed."
    "${COMPOSE[@]}" down >/dev/null 2>&1
}

cmd_feed() {
    need_dataset "${1:-}"
    need_generated "$1"
    need_playground
    for database in $FEEDDBS; do
        if [ -z "$(psql_db postgres -tAc "SELECT 1 FROM pg_database WHERE datname = '$database'")" ]; then
            psql_db postgres -c "CREATE DATABASE $database" || die "Could not create $database."
            echo "Feed: created database $database"
        fi
    done
    psql_db database_enrol -c "SET client_min_messages = warning;
        CREATE TABLE IF NOT EXISTS course_enrolment (
        user_id varchar(100) NOT NULL,
        user_email varchar(255),
        course_id varchar(255) NOT NULL,
        role_name varchar(100),
        group_id varchar(254))" || die "Could not create course_enrolment."
    psql_db database_enrol < "$DATA/$1.feed.sql" || die "Could not load the feed."
    echo "Feed: database_enrol.course_enrolment holds $(psql_db database_enrol -tAc 'SELECT COUNT(*) FROM course_enrolment') rows"
}

cmd_moodle() {
    need_dataset "${1:-}"
    need_generated "$1"
    need_playground
    in_web apply.php "$1"
    if [ ! -f "$DATA/enrol_database_previous.json" ]; then
        docker cp -q "$WEB:$WORK/data/enrol_database_previous.json" "$DATA/enrol_database_previous.json"
    fi
}

cmd_sync() {
    need_playground
    docker exec -w /var/www/html "$WEB" php admin/cli/scheduled_task.php \
        --execute='\enrol_database\task\sync_enrolments' >/dev/null || die "The enrol_database sync failed."
    echo "Sync: enrol_database sync task ran"
}

cmd_after() {
    need_dataset "${1:-}"
    need_generated "$1"
    need_playground
    psql_db database_enrol < "$DATA/$1.after.sql" || die "Could not apply the feed changes."
    echo "Feed: leavers removed; database_enrol.course_enrolment now holds $(psql_db database_enrol -tAc 'SELECT COUNT(*) FROM course_enrolment') rows"
    in_web after_sync.php "$1"
}

cmd_status() {
    need_playground
    in_web status.php
    for database in $FEEDDBS; do
        if [ -n "$(psql_db postgres -tAc "SELECT 1 FROM pg_database WHERE datname = '$database'")" ]; then
            echo "Feed: $database has $(psql_db "$database" -tAc "SELECT COUNT(*) FROM pg_tables WHERE schemaname = 'public'") tables"
        else
            echo "Feed: $database does not exist"
        fi
    done
}

cmd_reset() {
    need_playground
    in_web reset.php
    rm -f "$DATA/enrol_database_previous.json"
    for database in $FEEDDBS; do
        if [ -n "$(psql_db postgres -tAc "SELECT 1 FROM pg_database WHERE datname = '$database'")" ]; then
            psql_db "$database" -c "DO \$\$ DECLARE t text; BEGIN
                FOR t IN SELECT tablename FROM pg_tables WHERE schemaname = 'public' LOOP
                    EXECUTE 'TRUNCATE TABLE public.' || quote_ident(t);
                END LOOP; END \$\$" || die "Could not empty $database."
            echo "Feed: $database emptied"
        fi
    done
}

case "${1:-}" in
    up)
        cmd_generate "${2:-}"
        cmd_feed "$2"
        cmd_moodle "$2"
        cmd_sync
        cmd_after "$2"
        cmd_status
        ;;
    generate|feed|moodle|after) "cmd_$1" "${2:-}" ;;
    sync|reset|status) "cmd_$1" ;;
    *) sed -n '2,13p' "$0" | sed 's/^# \{0,1\}//'; exit 64 ;;
esac
