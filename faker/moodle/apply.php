<?php
// Runs in the webserver container from /tmp: php apply.php <datadir> <dataset>
// Creates the data set's categories, courses and people through Moodle's APIs, then points
// enrol_database at the playground feed with learn's settings. The previous enrol_database
// settings are saved to <datadir>/enrol_database_previous.json for reset.

define('CLI_SCRIPT', true);
require('/var/www/html/config.php');
require_once($CFG->dirroot . '/course/lib.php');
require_once($CFG->dirroot . '/user/lib.php');

[, $datadir, $dataset] = $argv + [null, '', ''];
$data = json_decode(file_get_contents("$datadir/$dataset.json"), true, 512, JSON_THROW_ON_ERROR);

if ($DB->record_exists('course_categories', ['idnumber' => 'FAKER'])) {
    fwrite(STDERR, "Faker data already exists. Run reset first.\n");
    exit(2);
}

$previousfile = "$datadir/enrol_database_previous.json";
if (!file_exists($previousfile)) {
    $previous = (array) get_config('enrol_database');
    unset($previous['version']);
    file_put_contents($previousfile, json_encode(
        ['settings' => $previous, 'enabled' => enrol_is_enabled('database')],
        JSON_PRETTY_PRINT
    ));
}

$top = core_course_category::create(['name' => $data['categoryname'], 'idnumber' => 'FAKER']);
$categoryids = [];
foreach ($data['categories'] as $category) {
    $categoryids[$category['key']] = core_course_category::create([
        'name' => $category['name'],
        'idnumber' => $category['idnumber'],
        'parent' => $top->id,
    ])->id;
}

foreach ($data['courses'] as $course) {
    create_course((object) [
        'fullname' => $course['fullname'],
        'shortname' => $course['shortname'],
        'idnumber' => $course['idnumber'],
        'category' => $categoryids[$course['category']],
        'visible' => $course['visible'] ? 1 : 0,
    ]);
}

foreach ($data['people'] as $person) {
    user_create_user((object) [
        'auth' => 'manual',
        'confirmed' => 1,
        'mnethostid' => $CFG->mnet_localhost_id,
        'username' => $person['username'],
        'password' => random_string(24),
        'email' => $person['email'],
        'firstname' => $person['firstname'],
        'lastname' => $person['lastname'],
        'idnumber' => $person['idnumber'],
        'suspended' => $person['suspended'] ? 1 : 0,
    ], true, false);
}

// Learn's settings (faker/project.md), with only the connection pointed at the playground feed.
$settings = [
    'dbtype' => 'postgres7',
    'dbhost' => 'db',
    'dbuser' => getenv('MOODLE_DOCKER_DBUSER'),
    'dbpass' => getenv('MOODLE_DOCKER_DBPASS'),
    'dbname' => 'database_enrol',
    'dbencoding' => 'utf-8',
    'dbsetupsql' => '',
    'dbsybasequoting' => 0,
    'debugdb' => 0,
    'remoteenroltable' => 'COURSE_ENROLMENT',
    'remotecoursefield' => 'COURSE_ID',
    'remoteuserfield' => 'USER_EMAIL',
    'remoterolefield' => 'ROLE_NAME',
    'remoteotheruserfield' => '',
    'localcoursefield' => 'idnumber',
    'localuserfield' => 'username',
    'localrolefield' => 'shortname',
    'localcategoryfield' => 'id',
    'defaultrole' => $DB->get_field('role', 'id', ['shortname' => 'student']),
    'unenrolaction' => 1, // Keep people who leave the feed, as on learn.
    'ignorehiddencourses' => 0,
    'newcoursetable' => '',
    'templatecourse' => '',
];
foreach ($settings as $key => $value) {
    set_config($key, $value, 'enrol_database');
}
\core\plugininfo\enrol::enable_plugin('database', 1);

printf("Moodle: %d categories, %d courses, %d people created; enrol_database enabled on database_enrol.\n",
    count($data['categories']) + 1, count($data['courses']), count($data['people']));
