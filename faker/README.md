# Faker

Fictional test courses, people and database enrolments for the playground. The plan and
decisions are in [project.md](project.md).

Run from the playground root, with Docker and the playground running:

```bash
faker/bin/faker.sh up database_basic
```

- `faker/bin/faker.sh status` shows what's there now.
- `faker/bin/faker.sh reset` deletes the faker data, empties the feed databases and
  restores the `enrol_database` settings.
- Running the script with no arguments lists the individual steps.

Data sets are parameter files in `config/`; copy one to make another. Generated files go
to `data/`, which git ignores.
