<?php
// Runs in the webserver container from /tmp: php status.php
// Read-only counts of the faker data in Moodle.

define('CLI_SCRIPT', true);
require('/var/www/html/config.php');

$top = $DB->get_record('course_categories', ['idnumber' => 'FAKER']);
$people = $DB->count_records_select('user', 'deleted = 0 AND ' . $DB->sql_like('idnumber', ':prefix'), ['prefix' => 'FAKER-%']);
printf("enrol_database: %s, feed database %s\n", enrol_is_enabled('database') ? 'enabled' : 'disabled',
    get_config('enrol_database', 'dbname') ?: '(not set)');
if (!$top) {
    printf("Moodle: no faker category; %d faker people.\n", $people);
    exit(0);
}

$like = $DB->sql_like('cc.path', ':path');
$counts = $DB->get_record_sql(
    "SELECT COUNT(DISTINCT c.id) AS courses,
            COALESCE(SUM(CASE WHEN e.enrol = 'database' AND ue.status = 0 THEN 1 ELSE 0 END), 0) AS active,
            COALESCE(SUM(CASE WHEN e.enrol = 'database' AND ue.status = 1 THEN 1 ELSE 0 END), 0) AS suspended
       FROM {course} c
       JOIN {course_categories} cc ON cc.id = c.category
  LEFT JOIN {enrol} e ON e.courseid = c.id
  LEFT JOIN {user_enrolments} ue ON ue.enrolid = e.id
      WHERE cc.id = :top OR $like",
    ['top' => $top->id, 'path' => $top->path . '/%']
);
printf("Moodle: %d faker courses, %d faker people, %d active and %d suspended database enrolments.\n",
    $counts->courses, $people, $counts->active, $counts->suspended);
