<?php
// Runs in the webserver container from /tmp: php after_sync.php <datadir> <dataset>
// Moodle-side changes after the first sync: enrolments suspended by something else,
// extra manual enrolments, and a course whose ID number is cleared.

define('CLI_SCRIPT', true);
require('/var/www/html/config.php');
require_once($CFG->dirroot . '/course/lib.php');

// Manual enrolments try to send welcome emails, which the .invalid domain blocks; keep the output quiet.
$CFG->debug = 0;
$CFG->debugdisplay = 0;

[, $datadir, $dataset] = $argv + [null, '', ''];
$data = json_decode(file_get_contents("$datadir/$dataset.json"), true, 512, JSON_THROW_ON_ERROR);
$after = $data['after'];

$course = fn(string $idnumber) => $DB->get_record('course', ['idnumber' => $idnumber], '*', MUST_EXIST);
$userid = fn(string $username) => $DB->get_field('user', 'id', ['username' => $username, 'deleted' => 0], MUST_EXIST);
$studentrole = $DB->get_field('role', 'id', ['shortname' => 'student']);

$database = enrol_get_plugin('database');
foreach ($after['suspendedelsewhere'] as $case) {
    $instance = $DB->get_record('enrol', ['courseid' => $course($case['course_id'])->id, 'enrol' => 'database'], '*', MUST_EXIST);
    $database->update_user_enrol($instance, $userid($case['username']), ENROL_USER_SUSPENDED);
}

$manual = enrol_get_plugin('manual');
foreach ($after['manualalso'] as $case) {
    $record = $course($case['course_id']);
    $instance = $DB->get_record('enrol', ['courseid' => $record->id, 'enrol' => 'manual']);
    if (!$instance) {
        $instance = $DB->get_record('enrol', ['id' => $manual->add_default_instance($record)], '*', MUST_EXIST);
    }
    $manual->enrol_user($instance, $userid($case['username']), $studentrole);
}

foreach ($after['clearidnumber'] as $idnumber) {
    update_course((object) ['id' => $course($idnumber)->id, 'idnumber' => '']);
}

printf("Moodle: %d enrolments suspended elsewhere, %d manual enrolments added, %d ID numbers cleared.\n",
    count($after['suspendedelsewhere']), count($after['manualalso']), count($after['clearidnumber']));
