<?php
namespace Debug;

class Profiler
{

    private $uri = 'http://host.docker.internal:8000/api/profiler/store';

    public function get(): \SpiralPackages\Profiler\Profiler
    {

        $storage = new \SpiralPackages\Profiler\Storage\WebStorage(
            new \Symfony\Component\HttpClient\NativeHttpClient(),
            $this->uri,
        );

        $driver = \SpiralPackages\Profiler\DriverFactory::detect();

        return new \SpiralPackages\Profiler\Profiler(
            storage: $storage,
            driver: $driver,
            appName: 'App',
            tags: [
                'env' => 'local',
            ]
        );

    }

}
