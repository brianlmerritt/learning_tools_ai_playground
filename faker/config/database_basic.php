<?php
// Parameters for the database_basic data set: core enrol_database only, small enough to
// read in Moodle. Copy this file to make another data set; see project.md.

return [
    'seed' => 20261023,
    'locale' => 'en_GB',
    'emaildomain' => 'faker.invalid',
    'categoryname' => 'Faker test data',

    // Academic years in the feed, and one earlier year whose course drops out of it.
    'currentyears' => ['202526', '202627'],
    'previousyear' => '202425',

    // Course ID numbers are <year><code>-<module>-<academic year>, e.g. 1VET-LOC-202526.
    'programmes' => [
        [
            'code' => 'VET',
            'name' => 'BVetMed',
            'years' => [1, 2],
            'modules' => ['LOC' => 'Locomotor', 'CAR' => 'Cardiovascular', 'NEU' => 'Neuroscience'],
        ],
        [
            'code' => 'AVN',
            'name' => 'Veterinary Nursing',
            'years' => [1],
            'modules' => ['ANA' => 'Anatomy', 'PHA' => 'Pharmacology'],
        ],
    ],
    'studentspercohort' => 10,
    'staffpercourse' => 2,

    // Feed ROLE_NAME values, which are Moodle role short names.
    'roles' => ['student' => 'student', 'staff' => 'editingteacher'],

    'scenarios' => [
        'leaverspercourse' => 2,     // students who left the feed but are still enrolled
        'staffleavers' => 1,         // a member of staff who left the feed
        'manualalso' => 3,           // leavers who also have a manual enrolment
        'suspendedaccounts' => 2,    // leavers whose Moodle account is suspended
        'suspendedelsewhere' => 2,   // leavers whose enrolment something else already suspended
        'messyemails' => 3,          // people still listed, with capitals and spaces in the feed
        'emptyidnumbercourses' => 1, // course whose ID number is cleared after the sync
        'hiddencourses' => 1,
    ],
];
