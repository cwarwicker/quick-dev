require_relative 'php.rb'

class Moodle < Php

    def install(container, qd)
       system("docker exec -it #{container} php admin/cli/install_database.php --agree-license --adminuser=admin --adminpass=moodle --adminemail=admin@local.host --fullname=Moodle --shortname=Moodle")
    end

    def purge(container, qd)
       system("docker exec -it #{container} php admin/cli/purge_caches.php")
    end

    def upgrade(container, qd)
       system("docker exec -it #{container} php admin/cli/upgrade.php --non-interactive")
    end

    def makecourse(container, qd)
       size = ARGV[1]
       name = ARGV[2]
       system("docker exec -it #{container} php admin/tool/generator/cli/maketestcourse.php --size=#{size} --shortname=#{name} --fullname=#{name}")
    end

    def phpunit(container, qd)
       opt = ARGV[1]
       if opt === "init"
          system("docker exec -it #{container} php admin/tool/phpunit/cli/init.php")
       else
          opts = ARGV[1..-1].join(' ')
          system("docker exec -it #{container} php admin/tool/phpunit/cli/util.php --run #{opts}")
       end
    end

end
