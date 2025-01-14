<?php
use AndrewNicols\Behat\ProfileManager;

// Chrome
$chrome = $CFG->behat_profiles['chrome'];
$headlesschrome = $CFG->behat_profiles['headlesschrome'];
$chrome['wd_host'] = $this->getConfig('seleniumHubUrl');
$headlesschrome['wd_host'] = $this->getConfig('seleniumHubUrl');

// Firefox
$firefox = $CFG->behat_profiles['firefox'];
$headlessfirefox = $CFG->behat_profiles['headlessfirefox'];
$firefox['wd_host'] = $this->getConfig('seleniumHubUrl');
$headlessfirefox['wd_host'] = $this->getConfig('seleniumHubUrl');

return [
    'chrome' => $chrome,
    'headlesschrome' => $headlesschrome,
    'firefox' => $firefox,
    'headlessfirefox' => $headlessfirefox,
];