<?php
require_once __DIR__ . '/../vendor/autoload.php';

foreach (glob(__DIR__ . '/*.php') as $file) {
    require_once $file;
}