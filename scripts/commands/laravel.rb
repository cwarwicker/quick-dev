class Laravel

    def artisan(container)
        cmd = ARGV[1..-1].join(' ')
        system("docker exec -it #{container} php artisan #{cmd}")
    end

end
