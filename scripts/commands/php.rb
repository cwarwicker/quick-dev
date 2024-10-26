class Php

    def install_debug(container, qd)

        # Install debugging services and configuration to work with buggregator.
        system("docker exec -it #{container} composer require --dev spatie/ray -W")
        system("docker exec -it #{container} composer require --dev sentry/sentry -W")
        system("docker exec -it #{container} composer require --dev inspector-apm/inspector-php -W")
        system("docker exec -it #{container} composer require --dev spiral-packages/profiler -W")

        Dir.glob(QUICK_DEV_PATH + '/.docker/templates/.config/*.php').each do |file_name|
            qd.copy_template(file_name, qd.project.dir + '/.debug/')
        end
    end

end