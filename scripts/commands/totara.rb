require_relative 'moodle.rb'

class Totara < Moodle

    def install(container, qd)
       system("docker exec -it #{container} php server/admin/cli/install_database.php --agree-license --adminuser=admin --adminpass=totara --adminemail=admin@local.host --fullname=Totara --shortname=Totara")
    end

    def purge(container, qd)
       system("docker exec -it #{container} php server/admin/cli/purge_caches.php")
    end

    def upgrade(container, qd)
       system("docker exec -it #{container} php server/admin/cli/upgrade.php --non-interactive")
    end

end
