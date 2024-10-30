require_relative 'python.rb'
class Django < Python

    def dj(container, qd)
        cmd = ARGV[1..-1].join(' ')
        system("docker exec -it #{container} django-admin #{cmd}")
    end

    def runserver(container, qd)
        system("docker exec -it #{container} python manage.py runserver 0.0.0.0:8000")
    end


end