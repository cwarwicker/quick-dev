require_relative 'php.rb'

class Moodle < Php

    RELATIVE_DIR = ""

    def install(container, qd)
       system("docker exec -it #{container} php #{self.class::RELATIVE_DIR}admin/cli/install_database.php --agree-license --adminuser=admin --adminpass=moodle --adminemail=admin@local.host --fullname=Moodle --shortname=Moodle")
    end

    def purge(container, qd)
       system("docker exec -it #{container} php #{self.class::RELATIVE_DIR}admin/cli/purge_caches.php")
    end

    def upgrade(container, qd)
       system("docker exec -it #{container} php #{self.class::RELATIVE_DIR}admin/cli/upgrade.php --non-interactive --allow-unstable")
    end

    def makecourse(container, qd)
       size = ARGV[1]
       name = ARGV[2]
       system("docker exec -it #{container} php #{self.class::RELATIVE_DIR}admin/tool/generator/cli/maketestcourse.php --size=#{size} --shortname=#{name} --fullname=#{name} --bypasscheck")
    end

    def makequiz(container, qd)
       course = ARGV[1]
       questions = ARGV[2]
       system("docker exec -it #{container} php /mnt/bulk_create_questions.php --course=#{course} --questions=#{questions}")
    end

    def phpunit(container, qd)
       opt = ARGV[1]
       if opt === "init"
          system("docker exec -it #{container} php #{self.class::RELATIVE_DIR}admin/tool/phpunit/cli/init.php")
       else
          opts = ARGV[1..-1].join(' ')
          system("docker exec -it #{container} php #{self.class::RELATIVE_DIR}admin/tool/phpunit/cli/util.php --run #{opts} --testdox --display-warnings --display-errors --display-notices --colors=always")
       end
    end

    def behat(container, qd)
       opt = ARGV[1]
       if opt === "init"
          # Clear out the behat data directory.
          system("docker exec -itd #{container} rm -rf /var/www/behatdata")
          # Start a local webserver because it needs to be able to connect locally and can't easily go through caddy from here.
          system("docker exec -itd #{container} php -S #{container}:80 -t /app")
          # Initialise the behat environment.
          system("docker exec -it #{container} php #{self.class::RELATIVE_DIR}admin/tool/behat/cli/init.php")
       elsif opt === "help"
          puts "Currently only supports chrome/headlesschrome profiles. You need to specify a profile or it will default to firefox."
          puts "Example: qd behat --profile=\"headlesschrome\" --tags=\"mod_forum\""
       else
          opts = ARGV[1..-1].join(' ')

          # Add default profile if we won't specify one.
          if not opts.include?('--profile')
             opts = opts + ' --profile="chrome"'
          end
          system("docker exec -it #{container} php #{self.class::RELATIVE_DIR}admin/tool/behat/cli/run.php #{opts}")
       end
    end

    def cron(container, qd)
       opts = ARGV[1..-1].join(' ')
       system("docker exec -it #{container} php #{self.class::RELATIVE_DIR}admin/cli/cron.php #{opts}")
    end

end
