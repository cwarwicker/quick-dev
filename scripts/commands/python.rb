require_relative 'all.rb'

class Python < All

    def python(container, qd)
        cmd = ARGV[1..-1].join(' ')
        system("docker exec -it #{container} python #{cmd}")
    end

end