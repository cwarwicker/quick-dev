require_relative 'php.rb'

class Moodle < Php

    def install(container, qd)
       system("docker exec -it #{container} php admin/cli/install_database.php --agree-license --adminuser=admin --adminpass=password --adminemail=admin@local.host")
    end

    def purge(container, qd)
       system("docker exec -it #{container} php admin/cli/purge_caches.php")
    end

    def upgrade(container, qd)
       system("docker exec -it #{container} php admin/cli/upgrade.php")
    end

end
