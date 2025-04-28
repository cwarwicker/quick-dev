require_relative 'php.rb'

class Mahara < Php

    RELATIVE_DIR = "./htdocs/"

    def install(container, qd)
       system("docker exec -it #{container} php #{self.class::RELATIVE_DIR}admin/cli/install.php --adminpassword=moodle --adminemail=admin@local.host --sitename=Mahara")
    end

end
