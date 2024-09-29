<?php
namespace .config templates\.config;

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
