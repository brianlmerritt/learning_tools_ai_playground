<?php
// Builds a fictional data set from a config/ file. Runs in the faker container and
// writes nothing to the playground; see project.md.

namespace PlaygroundFaker;

class DatasetGenerator
{
    private array $config;
    private \Faker\Generator $faker;
    private array $people = [];
    private int $personcount = 0;

    public function __construct(array $config)
    {
        $this->config = $config;
        $this->faker = \Faker\Factory::create($config['locale']);
        $this->faker->seed($config['seed']);
    }

    /**
     * Builds the data set: categories, courses, people, the initial feed and the changes
     * applied after the first sync.
     */
    public function build(string $name): array
    {
        $c = $this->config;
        $categories = [];
        $courses = [];
        $feed = [];
        $enrolled = []; // course idnumber => [username => role]

        foreach ($c['programmes'] as $programme) {
            $years = array_merge([$c['previousyear']], $c['currentyears']);
            foreach ($years as $academicyear) {
                $previous = $academicyear === $c['previousyear'];
                $categorykey = $programme['code'] . '-' . $academicyear;
                foreach ($programme['years'] as $year) {
                    $modules = $programme['modules'];
                    if ($previous) {
                        // Only one earlier course, with only its first module.
                        if ($programme !== $c['programmes'][0] || $year !== $programme['years'][0]) {
                            continue;
                        }
                        $modules = array_slice($modules, 0, 1, true);
                    }
                    $cohort = [];
                    for ($i = 0; $i < $c['studentspercohort']; $i++) {
                        $cohort[] = $this->person();
                    }
                    foreach ($modules as $module => $title) {
                        $idnumber = $year . $programme['code'] . '-' . $module . '-' . $academicyear;
                        $categories[$categorykey] = [
                            'key' => $categorykey,
                            'name' => $programme['name'] . ' ' . $this->yearlabel($academicyear),
                            'idnumber' => 'FAKER-' . $categorykey,
                        ];
                        $courses[$idnumber] = [
                            'idnumber' => $idnumber,
                            'shortname' => $idnumber,
                            'fullname' => sprintf('%s Year %d %s %s', $programme['name'], $year, $title,
                                $this->yearlabel($academicyear)),
                            'category' => $categorykey,
                            'visible' => true,
                            'previousyear' => $previous,
                        ];
                        foreach ($cohort as $username) {
                            $enrolled[$idnumber][$username] = $c['roles']['student'];
                        }
                        for ($i = 0; $i < $c['staffpercourse']; $i++) {
                            $enrolled[$idnumber][$this->person()] = $c['roles']['staff'];
                        }
                    }
                }
            }
        }

        foreach ($enrolled as $idnumber => $members) {
            foreach ($members as $username => $role) {
                $feed[] = [
                    'user_id' => $this->people[$username]['idnumber'],
                    'user_email' => $username,
                    'course_id' => $idnumber,
                    'role_name' => $role,
                ];
            }
        }

        $after = $this->scenarios($courses, $enrolled);
        foreach ($after['suspendedaccounts'] as $username) {
            $this->people[$username]['suspended'] = true;
        }
        foreach ($after['hidden'] as $idnumber) {
            $courses[$idnumber]['visible'] = false;
        }

        return [
            'dataset' => $name,
            'seed' => $c['seed'],
            'emaildomain' => $c['emaildomain'],
            'categoryname' => $c['categoryname'],
            'categories' => array_values($categories),
            'courses' => array_values($courses),
            'people' => array_values($this->people),
            'feed' => $feed,
            'after' => $after,
        ];
    }

    /**
     * Picks the scenario cases. Leavers are removed from the feed after the first sync; the
     * other cases are drawn from them, or from people still listed, so each is easy to find.
     */
    private function scenarios(array $courses, array $enrolled): array
    {
        $s = $this->config['scenarios'];
        $c = $this->config;
        $current = array_keys(array_filter($courses, fn($course) => !$course['previousyear']));
        $previous = array_keys(array_filter($courses, fn($course) => $course['previousyear']));

        $hidden = $this->pick($current, $s['hiddencourses']);
        $emptyidnumber = $this->pick(array_values(array_diff($current, $hidden)), $s['emptyidnumbercourses']);

        $leavers = [];
        $listed = [];
        foreach ($current as $idnumber) {
            $students = array_keys($enrolled[$idnumber], $c['roles']['student'], true);
            $staff = array_keys($enrolled[$idnumber], $c['roles']['staff'], true);
            $gone = $this->pick($students, $s['leaverspercourse']);
            foreach ($gone as $username) {
                $leavers[] = ['course_id' => $idnumber, 'username' => $username];
            }
            foreach (array_diff($students, $gone) as $username) {
                $listed[] = ['course_id' => $idnumber, 'username' => $username];
            }
        }
        $staffcourse = $this->pick($current, 1)[0];
        $staffleaver = $this->pick(array_keys($enrolled[$staffcourse], $c['roles']['staff'], true), $s['staffleavers']);
        foreach ($staffleaver as $username) {
            $leavers[] = ['course_id' => $staffcourse, 'username' => $username];
        }

        // Disjoint groups of leavers, so each case appears on its own.
        $pool = $this->faker->shuffle($leavers);
        $manualalso = array_splice($pool, 0, $s['manualalso']);
        $suspendedelsewhere = array_splice($pool, 0, $s['suspendedelsewhere']);
        $suspendedaccounts = array_column(array_splice($pool, 0, $s['suspendedaccounts']), 'username');

        $messy = [];
        foreach ($this->pick($listed, $s['messyemails']) as $case) {
            $username = $case['username'];
            $messy[] = $case + ['messy' => ' ' . ucfirst($username) . ' '];
        }

        return [
            'removefeed' => $leavers,
            'removecourses' => $previous,
            'messy' => $messy,
            'clearidnumber' => $emptyidnumber,
            'hidden' => $hidden,
            'manualalso' => $manualalso,
            'suspendedelsewhere' => $suspendedelsewhere,
            'suspendedaccounts' => $suspendedaccounts,
        ];
    }

    /**
     * Creates a fictional person and returns their username, which is also their email
     * address and their feed USER_EMAIL, as on learn.
     */
    private function person(): string
    {
        $this->personcount++;
        $first = $this->faker->firstName();
        $last = $this->faker->lastName();
        $clean = fn($text) => preg_replace('/[^a-z]/', '', strtolower($text));
        $username = sprintf('%s.%s.%d@%s', $clean($first), $clean($last), $this->personcount,
            $this->config['emaildomain']);
        $this->people[$username] = [
            'username' => $username,
            'email' => $username,
            'firstname' => $first,
            'lastname' => $last,
            'idnumber' => sprintf('FAKER-%05d', $this->personcount),
            'suspended' => false,
        ];
        return $username;
    }

    /**
     * Picks up to $count items, in a repeatable order for the seed.
     */
    private function pick(array $items, int $count): array
    {
        if ($count <= 0 || !$items) {
            return [];
        }
        return array_values($this->faker->randomElements($items, min($count, count($items))));
    }

    /**
     * 202526 becomes 2025/6.
     */
    private function yearlabel(string $academicyear): string
    {
        return substr($academicyear, 0, 4) . '/' . substr($academicyear, 5, 1);
    }
}
