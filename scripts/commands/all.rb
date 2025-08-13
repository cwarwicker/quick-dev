class All

    def initialize(data)
    end

    def npm(container, qd)
        cmd = ARGV[1..-1].join(' ')
        system("docker exec -it #{container} npm #{cmd}")
    end

    def cmd(container, qd)
        cmd = ARGV[1..-1].join(' ')
        system("docker exec -it #{container} #{cmd}")
    end

    def watch_logs(container, qd)
        system("tail -F #{QUICK_DEV_PATH}/logs/#{qd.project.name}.log")
    end

end
