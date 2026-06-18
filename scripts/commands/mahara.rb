require_relative 'php.rb'

class Mahara < Php

    RELATIVE_DIR = "./htdocs/"

   def install(container, qd)
      system("docker exec -it --user www-data #{container} php #{self.class::RELATIVE_DIR}admin/cli/install.php --adminpassword=mahara --adminemail=admin@local.host --sitename=Mahara")
   end

   def upgrade(container, qd)
      system("docker exec -it --user www-data #{container} php #{self.class::RELATIVE_DIR}admin/cli/upgrade.php")
   end

   def cron(container, qd)
      opts = ARGV[1..-1].join(' ')
      system("docker exec -it #{container} php #{self.class::RELATIVE_DIR}/lib/cron.php #{opts}")
   end

   def purge(container, qd)
      system("docker exec -it #{container} php #{self.class::RELATIVE_DIR}/admin/cli/clear_caches.php")
   end

end
