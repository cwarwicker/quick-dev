class Moodle

    def install(container)
       system("docker exec -it #{container} php /var/www/site/admin/cli/install_database.php --agree-license --adminuser=admin --adminpass=password --adminemail=admin@local.host")
    end

    def purge(container)
       system("docker exec -it #{container} php /var/www/site/admin/cli/purge_caches.php")
    end

end
