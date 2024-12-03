<?php
use AndrewNicols\Behat\ProfileManager;
$chrome = $CFG->behat_profiles['chrome'];
$chrome['wd_host'] = $this->getConfig('chromeSeleniumUrl');

$headlesschrome = $CFG->behat_profiles['headlesschrome'];
$headlesschrome['wd_host'] = $this->getConfig('chromeSeleniumUrl');

return [
    'chrome' => $chrome, 'headlesschrome' => $headlesschrome
];