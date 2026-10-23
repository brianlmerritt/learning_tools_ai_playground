---
name: moodle-plugin-testing
description: Test a Moodle plugin against Brian's Docker playground (learning_tools_ai_playground) without installing it, changing core/moodle, moodle-docker, the submodules or the dev site's database. Use for any Moodle plugin test run, from any project.
---

# Moodle plugin testing on the playground

The playground at `/Volumes/MacMiniSSD/dev/docker/learning_tools_ai_playground` is
Brian's managed environment. Plugins arrive in its `core/moodle` only through his
`configs/moodle.yaml` and submodule scripts, after he pushes. Test there only with
the two tools below, and choose the one that fits what needs checking at the time.

## Never

- Copy, rsync or symlink anything into `core/moodle` or a plugin checkout there.
- Install, upgrade or uninstall plugins on the dev site. Initialise or drop the
  playground's own PHPUnit or Behat environment. Install software in its containers.
- Start or stop the playground or Docker, or run git commands in the playground.

If Docker, or the playground when a tool needs it, is not running, ask Brian to
start it and wait. The tools check this and exit with code 69 and a message.

## Tool 1: harness against the running playground

```bash
/Volumes/MacMiniSSD/dev/docker/learning_tools_ai_playground/bin/plugin_harness.sh <plugin-dir> <harness.php>
```

- **Use for:** quick checks of unpushed classes against the real playground Moodle
  and its data. Needs the playground running.
- **What it does:** copies the plugin folder and the harness into a unique folder
  under the webserver container's `/tmp`, runs the harness with the copied plugin
  folder as argument 1, and always deletes that folder. It records `core/moodle`
  git status and the pending-upgrade state before and after the run, and fails if
  either changed.
- **Harness contract:** start from `harness_example.php` in this folder. Define
  `CLI_SCRIPT`, require `/var/www/html/config.php`, then require the plugin's
  classes directly. Put any database writes in a delegated transaction and end
  with `$DB->force_transaction_rollback()`. PostgreSQL id sequences still advance.
  Exit non-zero on failure.
- **Cannot cover:** the plugin's language strings, its own tables, admin pages,
  install or upgrade.

## Tool 2: PHPUnit in separate test containers

```bash
/Volumes/MacMiniSSD/dev/docker/learning_tools_ai_playground/bin/plugin_phpunit.sh <plugin-dir> <moodle-path>
```

- **Example:** `<moodle-path>` is `local/rvc_enrolment_management` for
  `local_rvc_enrolment_management`.
- **Use for:** the plugin's full PHPUnit suite on unpushed code. It doesn't need
  the playground running, only Docker.
- **What it does:** compose project `plugintest` (`docker-compose.plugintest.yml`)
  copies `core/moodle` (mounted read-only) into its own volume, puts the plugin at
  `<moodle-path>`, initialises PHPUnit against its own PostgreSQL 16 and runs
  `<component>_testsuite`. The test containers are removed afterwards; the volumes
  are kept for speed.
- **Timing:** the first run, and any run after a version bump, rebuilds the PHPUnit
  site, which takes several minutes. Run it in the background and wait for it to
  finish.
- **Reset:** `docker compose -p plugintest -f /Volumes/MacMiniSSD/dev/docker/learning_tools_ai_playground/docker-compose.plugintest.yml down -v`
  removes the test volumes.
- **Scope today:** Moodle 4.5 (the playground's checkout) on PostgreSQL. Testing may
  later be expanded to MySQL 8.4 (production) and Moodle 5.3.

## Tool 3: code style (moodle-cs), before every hand-over

```bash
/Volumes/MacMiniSSD/dev/docker/learning_tools_ai_playground/bin/plugin_phpcs.sh <plugin-dir> [--fix]
```

- **Use for:** the same check as the plugins' CI (`phpcs --standard=moodle`,
  failing on any error or warning). Run it on every plugin change before handing
  the work back to Brian. It doesn't need the playground running.
- **`--fix`:** runs `phpcbf` first, which corrects the auto-fixable problems in the
  plugin's own repository, the only place it writes. Fix the rest by hand and run
  it again until it passes.
- **First run:** installs moodle-cs with Composer into the kept volume
  `plugintest_phpcstools`, which needs `repo.packagist.org`. On 2026-10-23 the RVC
  network's DNS (Jisc protective DNS, `landing.soc.ja.net`) blocked that host, so
  the install failed. Don't work around the block; tell Brian, and rely on CI until
  it's resolved.

## Not covered locally

PHPDoc, savepoints and MySQL run in the plugin's GitHub Actions after Brian pushes.

## After Brian installs a plugin through `configs/moodle.yaml`

Each plugin's PLAN.md carries an item to rerun its full PHPUnit suite in the
playground itself, now that the plugin is installed. Run it with
`vendor/bin/phpunit --testsuite <component>_testsuite` in `moodle-docker-webserver-1`
from `/var/www/html`. If `php admin/tool/phpunit/cli/util.php --diag` says the
environment needs initialising, ask Brian before running `init.php`.

## Reporting

Say which tool ran, on which plugin path and commit or working tree, and give the
test results. Confirm the playground-unchanged line from the harness, or that the
`plugintest` containers were removed. Name anything left behind.
