<?php
namespace Debug;

/**
 * Service container for any debugging tools which require objects.
 */
class Container {

    /**
     * Get a class object
     * @param string $className
     * @return mixed
     * @throws \ReflectionException
     */
    public static function get(string $className): object {

        $reflection = new \ReflectionClass($className);
        $constructor = $reflection->getConstructor();

        if (is_null($constructor)) {
            return new $className();
        }

        $array = [];

        foreach ($constructor->getParameters() as $param) {
            $type = $param->getType();
            $array[] = static::get((string)$type);
        }

        return new $className(...$array);

    }

}