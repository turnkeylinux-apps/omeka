#!/usr/bin/php
<?php

if ($argc !== 4) {
    fwrite(STDERR, "Usage: omeka-user.php USERNAME PASSWORD EMAIL\n");
    exit(2);
}

chdir('/var/www/omeka');
require_once 'bootstrap.php';
require_once 'Omeka/Application.php';

$application = new Omeka_Application(APPLICATION_ENV);
$application->bootstrap([
    'Config', 'Logger', 'Db', 'Options', 'Pluginbroker', 'View', 'Locale',
]);

$user = get_db()->getTable('User')->findBySql('username = ?', [$argv[1]], true);
if (!($user instanceof User)) {
    fwrite(STDERR, "Omeka user was not found\n");
    exit(1);
}

$user->setPassword($argv[2]);
$user->email = $argv[3];
if ($user->getDb()->insert('User', $user->toArray()) !== (int) $user->id) {
    fwrite(STDERR, "Omeka user update failed\n");
    exit(1);
}
set_option('administrator_email', $argv[3]);
