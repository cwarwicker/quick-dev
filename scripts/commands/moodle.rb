class Moodle

    def install(container)
       system("docker exec -it #{container} php admin/cli/install_database.php --agree-license --adminuser=admin --adminpass=password --adminemail=admin@local.host")
    end

    def purge(container)
       system("docker exec -it #{container} php admin/cli/purge_caches.php")
    end

    def upgrade(container)
       system("docker exec -it #{container} php admin/cli/upgrade.php")
    end

end
