# Faker: test data for the playground

Status: plan for discussion (2026-10-23). Nothing is built yet.

## Why

Plugins that act on external enrolment feeds, starting with
`local_rvc_enrolment_management`, need realistic courses, people and database
enrolments to click-test. learn-uat has real data, but fixing a bug there needs the
hosting partner to refresh it, which takes 2 to 4 working days. Fictional data in the
playground is less perfect but turns around in minutes.

## What is decided

- This is an addition to the playground, not part of any plugin. Code, parameters and
  generated data live in this `faker/` folder.
- Faker runs in its own container, with its parameters in files here, so new data
  sets can be added later without rewriting it. It is meant to be extensible, but
  simpler than Laravel's factory system.
- Feed databases go in the playground's existing PostgreSQL (`moodle-docker-db-1`),
  as two new databases:
  - `database_enrol`, the feed for core `enrol_database`, mirroring `Moodle_Snapshot`;
  - `database_extended_enrol`, the feed for `enrol_databaseextendedv2`, created now but
    not populated.
- Core database enrolment comes first. The extended plugin is not ignored: Brian will
  look at the real data's shape first.
- The data is fictional. No real names, emails or identifiers.

## Playground today (checked 2026-10-23)

- Moodle 4.5.15 on PostgreSQL 16. `local_rvc_enrolment_management` is installed (v0.2.0).
- One course besides the front page, and 13 users.
- Enabled enrolment methods are manual, guest, self and cohort. `enrol_database` is
  installed but disabled and unconfigured. Its default "external unenrol action" would
  unenrol people who leave the feed, whereas learn keeps them, so the faker must set it.
- `enrol_databaseextendedv2` is not installed. It is closed source.
- Moodle 4.5 has no `enrol/database/cli/sync.php`. The sync runs as the scheduled task
  `\enrol_database\task\sync_enrolments`.

## Proposed shape

```
faker/
  project.md            this plan
  README.md             how to run it, once built
  docker-compose.faker.yml
  Dockerfile            faker container: PHP CLI and Faker
  config/               parameters, one file per data set (sizes, years, scenario mix)
  src/                  factories (category, course, person, feed row) and the scenario runner
  moodle/               PHP CLI scripts run inside the webserver container
  data/                 generated data sets (git-ignored)
  bin/faker.sh          entry point
```

`bin/faker.sh` commands:

| Command | What it does |
|---|---|
| `generate <dataset>` | Builds a fictional data set from `config/<dataset>` into `data/`: categories, courses, people, intended enrolments and feed rows. Writes nothing to the playground. |
| `feed <dataset>` | Creates `database_enrol` and `database_extended_enrol` if missing, then loads `COURSE_ENROLMENT` in `database_enrol` from the data set. |
| `moodle <dataset>` | Copies the Moodle scripts and the data set into the webserver container's `/tmp`. It creates the categories, courses and people through Moodle's own APIs, then configures and enables `enrol_database` to match learn's settings. It saves the previous settings first. |
| `sync` | Runs `\enrol_database\task\sync_enrolments`, so enrolments are created exactly as in production. |
| `leave <dataset>` | Removes the data set's "leavers" from the feed. With unenrol action "keep", Moodle keeps them active, which is the case the plugin handles. |
| `reset` | Deletes everything marked as faker data from Moodle, empties the feed tables and restores the saved `enrol_database` settings. |
| `status` | Counts what's there now, read-only. |

### Marking faker data, so reset removes only it

- Courses go under one top-level category, "Faker test data".
- People get an email domain that cannot be real (for example `@faker.invalid`) and a
  `FAKER-` prefix on their Moodle ID number.
- Usernames match the feed's `USER_EMAIL`, as on learn.

### First data set: `database_basic`

Small enough to read, for example 12 courses and 150 people. Course ID numbers follow
the real shape, for example `1VET-LOC-202526`, across two academic years. It covers:

- people still in the feed (students and staff, by role short name);
- people who left the feed but are still enrolled;
- a course from a previous year with no feed rows at all;
- a course with an empty ID number;
- a person who also has a manual enrolment;
- a person whose Moodle account is suspended;
- feed emails with capitals or surrounding spaces;
- database enrolments already suspended by something else;
- a hidden course.

## Rules it follows

- It never writes to `core/moodle` files or git. Moodle-side scripts run from the
  webserver container's `/tmp`, as the plugin harness does.
- It changes the playground's database and `enrol_database` settings by design. Under
  `~/.claude/CLAUDE.md` section 5 that is something Brian runs, or a specific exception
  he grants (open point 1).
- `reset` returns Moodle and the feed databases to their pre-faker state, apart from
  Moodle's logs and the PostgreSQL id sequences.

## Open points

1. **Who runs it:** Brian only, or agents too, once agreed (an exception in CLAUDE.md
   section 5 for `faker/bin/faker.sh`).
2. **Language:** PHP with `fakerphp/faker`, which is the same language as the
   Moodle-side scripts and the Faker that Laravel uses, or Python with `Faker`. PHP
   keeps one language; it needs packagist, which was briefly blocked by the network DNS
   on 2026-10-23.
3. **Data shape:** Brian to look at real data for sizes, role names, ID number patterns
   and the feed's columns (`user_id`, `user_email`, `course_id`, `role_name`, `group_id`).
4. **Extended plugin:** whether its code can be installed on the playground. Without it,
   `database_extended_enrol` can hold data but nothing reads it.
5. **Feed engine:** learn's core feed is SQL Server over ODBC. PostgreSQL with the same
   table and column names tests the same plugin logic, but not the ODBC layer.
6. **Reset:** whether to also delete the two feed databases, or only empty them.
