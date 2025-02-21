<?php
namespace Debug;

class Inspector {

    private $key = 'buggregator';
    private $uri = 'http://inspector@host.docker.internal:8000';

    /**
     * Return the actual Inspector object to use
     * @return \Inspector\Inspector
     * @throws \Inspector\Exceptions\InspectorException
     */
    public function get(): \Inspector\Inspector {

        $configuration = new \Inspector\Configuration($this->key);
        $configuration->setUrl($this->uri);
        return new \Inspector\Inspector($configuration);

    }

}

/*

=========================== EXAMPLE ===========================

// Get the Inspector object from our service container.
$inspector = \Debug\Container::get('Debug\Inspector')->get();

// Start our inspection with a name.
$inspector->startTransaction('My Inspection')->markAsRequest();

// Set a label for our transaction.
$inspector->transaction()->addContext('label', ['foo' => 'bar']);

// First code segment should take the longest.
$inspector->addSegment(function () {

    echo 'hello?';
    sleep(4);
    echo 'ok bye then';

}, 'test', 'segment_1');

// Second code segment should be very quick.
$inspector->addSegment(function () {

    $weare = 'cool';
    if ($weare === 'cool') {
        return true;
    }

}, 'test', 'segment_2');

// End the transaction with a 200 response. (Default will just be string "SUCCESS" if not specified).
$inspector->transaction()->setResult(200);

*/
