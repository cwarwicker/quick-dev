class All

    def npm(container)
        cmd = ARGV[1..-1].join(' ')
        system("docker exec -it #{container} npm #{cmd}")
    end

end
