class All

    def npm(container, qd)
        cmd = ARGV[1..-1].join(' ')
        system("docker exec -it #{container} npm #{cmd}")
    end

    def cmd(container, qd)
        cmd = ARGV[1..-1].join(' ')
        system("docker exec -it #{container} #{cmd}")
    end

end
