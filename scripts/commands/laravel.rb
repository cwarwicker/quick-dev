require_relative 'php.rb'

class Laravel < Php

    def artisan(container, qd)
        cmd = ARGV[1..-1].join(' ')
        system("docker exec -it #{container} php artisan #{cmd}")
    end

    def refresh(container, qd)
        cmd = ARGV[1..-1].join(' ')
        system("docker exec -it #{container} bash -c 'php artisan migrate:fresh && php artisan db:seed #{cmd}'")
    end

end
