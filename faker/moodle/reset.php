<?php
// Runs in the webserver container from /tmp: php reset.php <datadir>
// Deletes everything marked as faker data (the "FAKER" category tree and people whose ID
// number starts "FAKER-"), then restores the saved enrol_database settings.

define('CLI_SCRIPT', true);
require('/var/www/html/config.php');
require_once($CFG->dirroot . '/course/lib.php');
require_once($CFG->dirroot . '/user/lib.php');

[, $datadir] = $argv + [null, ''];

// Don't back up faker courses into the recycle bin as they are deleted (this run only).
$CFG->forced_plugin_settings['tool_recyclebin']['categorybinenable'] = 0;
$CFG->forced_plugin_settings['tool_recyclebin']['coursebinenable'] = 0;

$courses = 0;
if ($top = $DB->get_record('course_categories', ['idnumber' => 'FAKER'])) {
    $courses = $DB->count_records_sql(
        'SELECT COUNT(1) FROM {course} c JOIN {course_categories} cc ON cc.id = c.category
          WHERE cc.id = :top OR ' . $DB->sql_like('cc.path', ':path'),
        ['top' => $top->id, 'path' => $top->path . '/%']
    );
    core_course_category::get($top->id, MUST_EXIST, true)->delete_full(false);
}

$people = $DB->get_records_select('user', 'deleted = 0 AND ' . $DB->sql_like('idnumber', ':prefix'), ['prefix' => 'FAKER-%']);
foreach ($people as $person) {
    delete_user($person);
}
printf("Moodle: %d courses and %d people deleted.\n", $courses, count($people));

$previousfile = "$datadir/enrol_database_previous.json";
if (!file_exists($previousfile)) {
    echo "No saved enrol_database settings, so they were left as they are.\n";
    exit(0);
}
$previous = json_decode(file_get_contents($previousfile), true, 512, JSON_THROW_ON_ERROR);
foreach (array_keys((array) get_config('enrol_database')) as $key) {
    if ($key !== 'version' && !array_key_exists($key, $previous['settings'])) {
        unset_config($key, 'enrol_database');
    }
}
foreach ($previous['settings'] as $key => $value) {
    set_config($key, $value, 'enrol_database');
}
\core\plugininfo\enrol::enable_plugin('database', $previous['enabled'] ? 1 : 0);
echo "enrol_database settings restored to their saved state.\n";
