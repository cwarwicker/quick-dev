#!/bin/bash

~/.config/composer/vendor/bin/phpcs --report=json /app/public/mod/assign/backup/moodle2/backup_assign_stepslib.php 2>/dev/null | awk '/^\{/,/^\}$/' > .cs.json