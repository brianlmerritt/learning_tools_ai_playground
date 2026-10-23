<?php
// Runs in the faker container: php bin/generate.php <dataset>
// Writes data/<dataset>.json, data/<dataset>.feed.sql and data/<dataset>.after.sql.

require __DIR__ . '/../vendor/autoload.php';

$name = $argv[1] ?? '';
if (!preg_match('/^[a-z0-9_]+$/', $name) || !is_file(__DIR__ . "/../config/$name.php")) {
    fwrite(STDERR, "Usage: php bin/generate.php <dataset>, with config/<dataset>.php present\n");
    exit(64);
}

$data = (new PlaygroundFaker\DatasetGenerator(require __DIR__ . "/../config/$name.php"))->build($name);

$q = fn(string $value) => "'" . str_replace("'", "''", $value) . "'";

$feed = ["TRUNCATE course_enrolment;"];
foreach ($data['feed'] as $row) {
    $feed[] = sprintf('INSERT INTO course_enrolment (user_id, user_email, course_id, role_name) VALUES (%s, %s, %s, %s);',
        $q($row['user_id']), $q($row['user_email']), $q($row['course_id']), $q($row['role_name']));
}

$after = [];
foreach ($data['after']['removefeed'] as $case) {
    $after[] = sprintf('DELETE FROM course_enrolment WHERE course_id = %s AND user_email = %s;',
        $q($case['course_id']), $q($case['username']));
}
foreach ($data['after']['removecourses'] as $idnumber) {
    $after[] = sprintf('DELETE FROM course_enrolment WHERE course_id = %s;', $q($idnumber));
}
foreach ($data['after']['messy'] as $case) {
    $after[] = sprintf('UPDATE course_enrolment SET user_email = %s WHERE course_id = %s AND user_email = %s;',
        $q($case['messy']), $q($case['course_id']), $q($case['username']));
}

$dir = __DIR__ . '/../data';
if (!is_dir($dir)) {
    mkdir($dir);
}
file_put_contents("$dir/$name.json", json_encode($data, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES));
file_put_contents("$dir/$name.feed.sql", implode("\n", $feed) . "\n");
file_put_contents("$dir/$name.after.sql", implode("\n", $after) . "\n");

printf("Generated %s: %d courses, %d people, %d feed rows, %d leavers.\n", $name, count($data['courses']),
    count($data['people']), count($data['feed']), count($data['after']['removefeed']));
