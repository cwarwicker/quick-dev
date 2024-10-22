require 'fileutils'
require 'json'
require 'optparse'
require 'yaml'
require "tty-prompt"
require "tty-markdown"
require_relative 'project.rb'
require_relative 'const.rb'
Dir["#{File.dirname(__FILE__)}/commands/*.rb"].each {|file| require file }

class QuickDev
    
    attr_accessor :project, :log, :prompt

    def initialize()

        @prompt = TTY::Prompt.new

        # Wipe the QuickDev log file.
        @log = QUICK_DEV_PATH + '/logs/quick-dev.log'
        if File.exist?(self.log)
            File.truncate(self.log, 0)
        end
        
    end
    
    # Write some text to the output and to the log file.
    # @param [String] text
    def say(text)
       
        File.open(self.log, 'a') { |f| f.write "#{text}\n" }
        puts text
    
    end

    # Run a command in Quick-Dev
    def run()

        # The command is the first argument to the script.
        # Everything else is considered arguments to that command.
        command = ARGV[0]

        case command
            
            when 'help'
                self.run_help()
            when 'config'
                self.run_config()
            when 'up'
                self.run_up()
            when 'stop'
                self.run_stop()
            when 'destroy'
                self.run_destroy()
            when 'connect'
                self.run_connect()
            when 'remove'
                self.run_remove()
            # when 'cluster'
            #     self.run_cluster()
            when 'services'
                self.run_services()
            else
                self.run_cmd()

        end
    
    end

    def run_help()
       
        puts <<-HELP
            Usage:          qd [command] [arguments]

            config          Configures the project with the services you require
            up              Starts the project containers
                            [-r|--rebuild] Rebuild the images
            stop            Stops the project containers
                            [-a|--all] Includes the core quick-dev system containers
            destroy         Stops and deletes the project containers
                            [-a|--all] Includes the core quick-dev system containers
            connect         Opens terminal connection to a project container (default: web)
                            [name] Specific container to connect to
            remove          Completely remove the project from quick-dev
            services        Lists all running services in the project and their endpoints
                            [-a|--all] Includes the core quick-dev services
            <x>             Runs a project-specific command.
                            [command] The command to run. E.g. `artisan tinker` (laravel) or `purge` (moodle)
            cmd             Run any arbitrary command on the application console
                            [command] The command to run. E.g. `echo 'Hello World'`                        
            
        HELP
            
    end

    def get_class(class_name)

       # If the class exists return a new instance of it. Else return false.
       return Module.const_get(class_name).new
       rescue NameError
           return false

    end

    # Check if we are currently within an apps project directory.
    def is_in_app_dir()
        return Dir.pwd.start_with?(QUICK_DEV_PATH + '/apps/')
    end

    def run_config()

        # Must be inside an app directory.
        unless self.is_in_app_dir()
           abort("Must be inside an app")
        end

        # Load up what info we can from the dir.
        @project = Project.create()

        # Check if the config file already exists.
        config_file = project.dir + '/cfg.yaml'
        if File.exist?(config_file)
            if self.prompt.select("Existing #{config_file} found. Do you wish to make a backup?", %w(yes no)) === 'yes'
                FileUtils.mv(config_file, config_file + '.backup')
            end
        end

        # Load the services JSON.
        services = JSON.parse(File.read(QUICK_DEV_PATH + '/services.json'))

        # Start building the config Hash to create the yaml file.
        data = {}

        # What type of application are we running?
        data[:app] = {}
        data[:app][:type] = self.prompt.select("Application // What type of application will you be running?") do |menu|

            services['apps'].each do |obj|
                menu.choice obj['name'].capitalize, obj['name']
            end

        end

        # Next, do we want to use a preset image or define our own?
        which_image = self.prompt.select("Application // Which image do you want to use?") do |menu|

            menu.choice :custom

            i = 2
            services['apps'].each do |obj|
                if obj.key?('image')
                    menu.choice obj['image'], obj['image']
                    if obj['name'] == data[:app][:type]
                        menu.default i
                    end
                    i += 1
                end
            end

        end

        # If they asked for a custom image, let them input it.
        if which_image === 'custom'
            data[:app][:image] = self.prompt.ask("Please input the docker image to pull for this application: ")
        else
            data[:app][:image] = which_image
            # Are there any image args we need to gather?
            data[:app][:args] = {}
            services['apps'].each do |obj|
                if obj['name'] == data[:app][:type] and obj.key?('args')
                    obj['args'].each do |arg|
                        data[:app][:args][arg['name']] = self.prompt.ask("Image argument (#{arg['name']}): ", default: arg['default'])
                    end
                end
            end
        end

        # Add any additional required services linked to this type. E.g. Caddy for most web-based app types.
        services['apps'].each do |obj|
            if obj['name'] == data[:app][:type] and obj.key?('requires')
                data[:app][:requires] = []
                obj['requires'].each do |requires|
                    data[:app][:requires].push(requires)
                end
            end
        end

        # Choose the other services required for the app.
        other_services = self.prompt.multi_select("Which other services do you need?") do |menu|
           menu.default 1,2
           menu.choice :Database, 'db'
           menu.choice :Caching, 'cache'
        end

        # If we need a DB, what engine and version do we want?
        if other_services.include?('db')

            data[:db] = {}

            # Get the DB engine.
            data[:db][:type] = self.prompt.select("Choose a database engine") do |menu|
                services['db'].each do |obj|
                    menu.choice obj['name']
                end
            end

            # Get the version.
            which_version = self.prompt.select("Choose a #{data[:db][:type]} version") do |menu|
                services['db'].each do |obj|
                    if obj['name'] === data[:db][:type]
                        obj['versions'].each do |v|
                            menu.choice v
                        end
                        menu.choice :custom
                    end
                end
            end

            # If we chose custom, ask for a version tag.
            if which_version === 'custom'
                data[:db][:version] = self.prompt.ask("Which #{data[:db][:type]} version would you like? ")
            else
                data[:db][:version] = which_version
            end

        end

        # If we want a caching service.
        if other_services.include?('cache')

            data[:cache] = {}

            # Get the cache engine.
            data[:cache][:type] = self.prompt.select("Choose a caching system") do |menu|
                services['cache'].each do |obj|
                    menu.choice obj['name']
                end
            end

            # Get the version.
            which_version = self.prompt.select("Choose a #{data[:cache][:type]} version") do |menu|
                services['cache'].each do |obj|
                    if obj['name'] === data[:cache][:type]
                        obj['versions'].each do |v|
                            menu.choice v
                        end
                        menu.choice :custom
                    end
                end
            end

            # If we chose custom, ask for a version tag.
            if which_version === 'custom'
                data[:cache][:version] = self.prompt.ask("Which #{data[:cache][:type]} version would you like? ")
            else
                data[:cache][:version] = which_version
            end

        end

        # Save the config.
        File.write(config_file, data.to_yaml)

        # Reload the project.
        @project = Project.load()

        # Find all the global templates to be copied across.
        Dir.glob(QUICK_DEV_PATH + '/.docker/templates/*.template').each do |file_name|
            self.copy_template(file_name)
        end

        # Then any project type specific ones.
        Dir.glob(QUICK_DEV_PATH + '/.docker/templates/' + data[:app][:type] + '/*.template').each do |file_name|
            self.copy_template(file_name)
        end

        # Run any git patches which are required.
        Dir.glob(QUICK_DEV_PATH + '/.docker/templates/' + data[:app][:type] + '/*.patch').each do |file_name|
            self.apply_patch(file_name)
        end

        self.say("Project configured (#{config_file}). Run `qd up` to bring up the containers.")

    end

    def run_cmd()

        command = ARGV[0]

        # Project must be loaded.project_class
        @project = Project.load()

        project_class = self.get_class(self.project.type.capitalize)
        all_class = self.get_class('All')
        if project_class and project_class.respond_to?(command)
            container = self.project.name + '-app'
            project_class.send(command, container)
        elsif all_class and all_class.respond_to?(command)
            container = self.project.name + '-app'
            all_class.send(command, container)
        else
            self.say('Invalid command ('+command+') for project type ('+self.project.type+')')
        end

    end

    def get_service_status(container)
        return `docker inspect -f '{{.State.Status}}' #{container}`
    end

    def run_services(all = false)

        @project = Project.load()

        # Define additional arguments which can be passed to the `up` command.
        options = {}
        OptionParser.new do |opts|
            opts.banner = "Usage: qd services [options]"
            opts.on('-a', '--all', 'Stop all the core quick-dev containers as well') { options[:all] = true }
        end.parse!

        # Load the docker-compose file (we use this instead of cfg.yml incase of custom changes).
        space = "\t\t"
        content = "# #{self.project.name} - SERVICES\n"
        content = content + "NAME#{space}\tTYPE#{space}STATUS#{space}URL\n"

        # Loop through the project services.
        self.project.config.each do |name, service|

            url = ''
            status = self.get_service_status(self.project.name + '-' + "#{name}").strip

            # Not sure at the moment how else to know which ones will have URLs.
            if "#{name}" == 'app'
                url = "https://#{self.project.name}.localhost"
            end

            content = content + "#{self.project.name}-#{name}#{space}#{service[:type]}#{space}#{status}#{space}#{url}\n"

        end

        if all or options[:all]
            content = content + "\n"
            content = content + "# Core - SERVICES\n"
            content = content + "NAME\t\t\t\tSTATUS\t\tURL\n"

            # These can be hard-coded as core services will be hard defined in the docker-compose anyway.
            content = content + "quick-dev-adminer\t\t#{self.get_service_status('quick-dev-adminer').strip}\t\thttp://adminer.localhost:8080?server=#{self.project.name}-db&username=user&db=main\n"
            content = content + "quick-dev-debug\t\t\t#{self.get_service_status('quick-dev-debug').strip}\t\thttp://buggregator.localhost:8000\n"
            content = content + "quick-dev-caddy\t\t\t#{self.get_service_status('quick-dev-caddy').strip}\t\t-\n"
        end

        self.say(TTY::Markdown.parse(content))

    end

    #
    # def run_cluster()
    #
    #     command = ARGV[1]
    #
    #     case command
    #
    #         when 'setup'
    #             self.run_cluster_setup()
    #         when 'destroy'
    #             self.run_cluster_destroy()
    #         else
    #             abort('Invalid command. Run `qd -h` for help.')
    #
    #     end
    #
    # end
    #
    # def run_cluster_setup()
    #
    #     self.say("Downloading minikube and configuring cluster for (#{self.project.name})")
    #     system("curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64 --output-dir #{QUICK_DEV_PATH}/.k8s/")
    #     system("sudo install #{QUICK_DEV_PATH}/.k8s/minikube-linux-amd64 /usr/local/bin/minikube")
    #     system("minikube start --driver=docker")
    #     system("minikube kubectl -- create namespace #{self.project.name}")
    #
    # end
    #
    # def run_cluster_destroy()
    #
    #     self.say("Destroying cluster (#{self.project.name})")
    #     system("minikube kubectl -- delete namespace #{self.project.name}")
    #
    #
    # end
    #
    # Remove the project from quick-dev.
    def run_remove()

        @project = Project.load()

        # Firstly stop and delete all the project containers.
        self.say("Deleting all containers in (#{self.project.name})")
        system("docker compose down")

        # Then remove any reference to this in the .docker/caddy/ directory.
        files = ['/.docker/caddy/' + self.project.name + '.caddy']
        files.each do |f|
            if File.exist?(QUICK_DEV_PATH + f)
                File.delete(QUICK_DEV_PATH + f)
                self.say("Removing [#{f}]")
            end
        end

        # Then remove the directory project.
        self.say("Removing project directory (#{self.project.dir})")
        FileUtils.remove_dir(self.project.dir)

        # TODO: Remove project logs (when done)
        # TODO: Remove project backups (when done)

    end

    # Connect to the terminal of one of the project containers.
    def run_connect()

        @project = Project.load()

        if !ARGV[1].nil?
            container = ARGV[1]
        else
            container = self.project.name + '-app'
        end

        system("docker exec -it #{container} bash")

    end
    
    # Start the project containers.
    def run_up()

        @project = Project.load()

        # Define additional arguments which can be passed to the `up` command.
        options = {}
        OptionParser.new do |opts|
            opts.banner = "Usage: qd up [options]"
            opts.on('-r', '--rebuild', 'Rebuild the docker image(s)') { options[:rebuild] = 'rebuild' }
            opts.on('-d', '--install-debug', 'Install debugging packages (Run first time you up the project)') { options[:debug] = 'debug' }
        end.parse!
        
        # Build the docker-compose file if it's missing.
        unless File.exist?(self.project.dir + '/docker-compose.yml')
            project.build_docker_compose()
        end

        # Create core network if it doesn't exist.
        system("docker network inspect #{QUICK_DEV_NETWORK} >/dev/null 2>&1 || (echo 'Creating quick-dev network:' && docker network create #{QUICK_DEV_NETWORK})")

        # Bring up core quick-dev containers.
        system("docker compose -f #{QUICK_DEV_PATH}/docker-compose.yml up -d")
        
        # Rebuild the project images if requested.
        if options[:rebuild]
            system("docker compose pull")
            system("docker compose build --no-cache")
        end
        
        # Bring up project containers.
        system("docker compose up -d")

        if options[:debug]
        
            # Install debugging services and configuration to work with buggregator.
            system("docker exec -it #{self.project.name}-app composer require --dev spatie/ray -W")
            system("docker exec -it #{self.project.name}-app composer require --dev sentry/sentry -W")
            system("docker exec -it #{self.project.name}-app composer require --dev inspector-apm/inspector-php -W")
            system("docker exec -it #{self.project.name}-app composer require --dev spiral-packages/profiler -W")

            Dir.glob(QUICK_DEV_PATH + '/.docker/templates/.config/*.php').each do |file_name|
                self.copy_template(file_name, self.project.dir + '/.debug/')
            end

        end

        if options[:debug]
            self.say("ACTION REQUIRED - Please add the following to your config/index page: `require_once './.debug/autoload.php';`")
        end
        self.say("\n")
        self.run_services(true)
    
    end

    # Stop the project containers.
    def run_stop()

        # Define additional arguments which can be passed to the `up` command.
        options = {:all => false}
        OptionParser.new do |opts|
            opts.banner = "Usage: qd stop [options]"
            opts.on('-a', '--all', 'Stop all the core quick-dev containers as well') { options[:all] = true }
        end.parse!

        # Stop the core quick-dev containers.
        if options[:all]
            system("docker compose -f #{QUICK_DEV_PATH}/docker-compose.yml stop")
        end

        # Stop the project containers.
        system("docker compose stop")

    end

    # Destroy the project containers.
    def run_destroy()

        # Define additional arguments which can be passed to the `up` command.
        options = {:all => false}
        OptionParser.new do |opts|
            opts.banner = "Usage: qd destroy [options]"
            opts.on('-a', '--all', 'Destroy all the core quick-dev containers as well') { options[:all] = true }
        end.parse!

        # Stop the core quick-dev containers.
        if options[:all]
            system("docker compose -f #{QUICK_DEV_PATH}/docker-compose.yml down")
        end

        system("docker compose down")

    end

    def apply_patch(patch_name)
        self.say("Applying git patch #{patch_name}")
        system("git apply #{patch_name}")
    end

    # Copy template files into the project directory
    # @param [String] file_name The template file to copy
    def copy_template(file_name, project_path = nil)
        
        # Replace placeholders with project values in the copied files.
        replace_map = {
            '%project.name%' => self.project.name,
            '%project.image%' => self.project.image,
            '%project.url%' => self.project.url,
            '%project.uri%' => self.project.uri,
            '%project.working_dir%' => self.project.working_dir,
            '%root%' => QUICK_DEV_PATH,
        }

        # If we didn't specify a directory, use the root.
        if project_path.nil?
            project_path = self.project.dir + '/'
        end

        # If the directory doesn't exist, create it.
        unless File.directory?(project_path)
            FileUtils.mkdir_p(project_path)
        end
        
        # This creates a "|" separated string with all the keys from the map.
        re = Regexp.new(replace_map.keys.map { |x| Regexp.escape(x) }.join('|'))
        
        # Remove the ".template" extension and prepend any other directory.
        new_file_name = project_path + File.basename(file_name.gsub(".template", ""))

        if File.basename(file_name) == 'caddy.template'

            caddy_path = QUICK_DEV_PATH + '/.docker/caddy/' + self.project.name + '.caddy'

            # Copy the file into the caddy directory.
            FileUtils.cp(file_name, caddy_path)

            # This makes the replacements in the file. Not entirely sure how it works.
            File.write(caddy_path, File.open(caddy_path, &:read).gsub(re, replace_map))

            self.say("#{file_name} ==> #{caddy_path}")

        else

            # Copy the file into the site directory.
            FileUtils.cp(file_name, new_file_name)

            # This makes the replacements in the file. Not entirely sure how it works.
            File.write(new_file_name, File.open(new_file_name, &:read).gsub(re, replace_map))

            self.say("#{file_name} ==> #{new_file_name}")

        end

    end

end