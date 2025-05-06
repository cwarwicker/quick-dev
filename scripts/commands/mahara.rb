require_relative 'php.rb'

class Mahara < Php

    RELATIVE_DIR = "./htdocs/"

    def install(container, qd)
       system("docker exec -it --user www-data #{container} php #{self.class::RELATIVE_DIR}admin/cli/install.php --adminpassword=mahara --adminemail=admin@local.host --sitename=Mahara")
    end

    def upgrade(container, qd)
        system("docker exec -it --user www-data #{container} php #{self.class::RELATIVE_DIR}admin/cli/upgrade.php")
     end

end
