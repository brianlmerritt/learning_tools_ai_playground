<?php
// Example harness for bin/plugin_harness.sh: copy it beside a plugin's own checks
// and adapt it. Argument 1 is the copied plugin folder in the container's /tmp.
//
// The plugin is not installed, so Moodle's autoloader cannot find its classes:
// require them directly. Language strings and install-time tables from the
// plugin are not available. Leave those to PHPUnit (bin/plugin_phpunit.sh).

define('CLI_SCRIPT', true);
require('/var/www/html/config.php');

$plugindir = $argv[1] ?? '';
$plugin = new stdClass();
require($plugindir . '/version.php');

// Load the plugin's classes, for example:
// require_once($plugindir . '/classes/local/feed_reader.php');

// Any check that writes to the database runs inside a transaction that is always
// rolled back, so the playground database keeps its data. PostgreSQL id sequences
// still advance, so later records skip a few ids.
// $DB->start_delegated_transaction();
// ... checks ...
// $DB->force_transaction_rollback();

echo "Moodle {$CFG->release}; loaded {$plugin->component} {$plugin->version} from {$plugindir}\n";
exit(0);
