require_relative 'php.rb'

class Moodle < Php

    RELATIVE_DIR = ""

    def install(container, qd)
       system("docker exec -it #{container} php #{self.class::RELATIVE_DIR}/admin/cli/install_database.php --agree-license --adminuser=admin --adminpass=moodle --adminemail=admin@local.host --fullname=Moodle --shortname=Moodle")
    end

    def purge(container, qd)
       system("docker exec -it #{container} php #{self.class::RELATIVE_DIR}admin/cli/purge_caches.php")
    end

    def upgrade(container, qd)
       system("docker exec -it #{container} php #{self.class::RELATIVE_DIR}admin/cli/upgrade.php --non-interactive")
    end

    def makecourse(container, qd)
       size = ARGV[1]
       name = ARGV[2]
       system("docker exec -it #{container} php #{self.class::RELATIVE_DIR}admin/tool/generator/cli/maketestcourse.php --size=#{size} --shortname=#{name} --fullname=#{name}")
    end

    def phpunit(container, qd)
       opt = ARGV[1]
       if opt === "init"
          system("docker exec -it #{container} php #{self.class::RELATIVE_DIR}admin/tool/phpunit/cli/init.php")
       else
          opts = ARGV[1..-1].join(' ')
          system("docker exec -it #{container} php #{self.class::RELATIVE_DIR}admin/tool/phpunit/cli/util.php --run #{opts}")
       end
    end

    def behat(container, qd)
       opt = ARGV[1]
       if opt === "init"
          # Initialise the behat environment.
          system("docker exec -it #{container} php #{self.class::RELATIVE_DIR}admin/tool/behat/cli/init.php")
          # Start a local webserver because it needs to be able to connect locally and can't easily go through caddy from here.
          system("docker exec -itd #{container} php -S internal:80 -t /app")
       elsif opt === "help"
          puts "Currently only supports chrome/headlesschrome profiles. You need to specify a profile or it will default to firefox."
          puts "Example: qd behat --profile=\"headlesschrome\" --tags=\"mod_forum\""
       else
          opts = ARGV[1..-1].join(' ')
          system("docker exec -it #{container} php #{self.class::RELATIVE_DIR}admin/tool/behat/cli/run.php #{opts}")
       end
    end

end
