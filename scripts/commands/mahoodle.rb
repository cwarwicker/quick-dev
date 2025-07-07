require_relative 'php.rb'

class Mahoodle < Php

    MOODLE_RELATIVE_DIR = "./moodle/"
    MAHARA_RELATIVE_DIR = "./mahara/htdocs/"

    def install_mahara(container, qd)
       system("docker exec -it --user www-data #{container} php #{self.class::MAHARA_RELATIVE_DIR}admin/cli/install.php --adminpassword=mahara --adminemail=admin@local.host --sitename=Mahara")
    end

    def upgrade_mahara(container, qd)
        system("docker exec -it --user www-data #{container} php #{self.class::MAHARA_RELATIVE_DIR}admin/cli/upgrade.php")
    end

    def install_moodle(container, qd)
       system("docker exec -it #{container} php #{self.class::MOODLE_RELATIVE_DIR}admin/cli/install_database.php --agree-license --adminuser=admin --adminpass=moodle --adminemail=admin@local.host --fullname=Moodle --shortname=Moodle")
    end

    def upgrade_moodle(container, qd)
       system("docker exec -it #{container} php #{self.class::MOODLE_RELATIVE_DIR}admin/cli/upgrade.php --non-interactive --allow-unstable")
    end

end
