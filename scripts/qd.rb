require 'fileutils'
require 'optparse'
require 'yaml'
require_relative 'project.rb'
require_relative 'const.rb'
Dir["#{File.dirname(__FILE__)}/commands/*.rb"].each {|file| require file }

class QuickDev
    
    attr_accessor :project, :log

    def initialize()
        
        # Wipe the QuickDev log file.
        @log = QUICK_DEV_PATH + '/logs/sys.log'
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
    
        # TODO: If we are not within a site, stop.
    
        # The command is the first argument to the script.
        # Everything else is considered arguments to that command.
        command = ARGV[0]

        case command
            
            when 'help'
                self.run_help()
            when 'create'
                self.run_create()
            when 'setup'
                self.run_setup()
            when 'add'
                self.run_add()
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
            when 'cluster'
                self.run_cluster()
            when 'services'
                self.run_services()
            else
                self.run_cmd()

        end
    
    end

    def run_help()
       
        puts <<-HELP
            Usage:          qd [command] [arguments]
            setup           Runs the initial quick-dev setup scripts to be run on first install
            add             Adds the current working dir as a site and copies core templates across
                            [-a|--additional] Copies project-specific (eg. moodle) templates into codebase dir
            up              Starts the project containers
                            [-r|--rebuild] Rebuild the images
            stop            Stops the project containers
                            [-a|--all] Includes the core quick-dev system containers
            destroy         Stops and deletes the project containers
                            [-a|--all] Includes the core quick-dev system containers
            connect         Opens terminal connection to a project container (default: web)
                            [name] Specific container to connect to
            remove          Completely remove the project from quick-dev
            <x..y>          Runs a project-specific command.
                            [command] The command to run. E.g. `composer install`
                        
            
        HELP
            
    end

    def get_class(class_name)

       # If the class exists return a new instance of it. Else return false.
       return Module.const_get(class_name).new
       rescue NameError
           return false

    end

    def run_cmd()

        command = ARGV[0]

        # Project must be loaded.project_class
        @project = Project.new()

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

    def run_cluster()

        command = ARGV[1]

        case command

            when 'setup'
                self.run_cluster_setup()
            when 'destroy'
                self.run_cluster_destroy()
            else
                abort('Invalid command. Run `qd -h` for help.')

        end

    end

    def run_cluster_setup()

        self.say("Downloading minikube and configuring cluster for (#{self.project.name})")
        system("curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64 --output-dir #{QUICK_DEV_PATH}/.k8s/")
        system("sudo install #{QUICK_DEV_PATH}/.k8s/minikube-linux-amd64 /usr/local/bin/minikube")
        system("minikube start --driver=docker")
        system("minikube kubectl -- create namespace #{self.project.name}")

    end

    def run_cluster_destroy()

        self.say("Destroying cluster (#{self.project.name})")
        system("minikube kubectl -- delete namespace #{self.project.name}")


    end
    
    # Remove the project from quick-dev.
    def run_remove()

        @project = Project.new()

        # Firstly stop and delete all the project containers.
        self.say("Deleting all containers in (#{self.project.name})")
        system("docker compose down")
        
        # Then remove the directory project.
        self.say("Removing project directory (#{self.project.dir})")
        FileUtils.remove_dir(self.project.dir)
        
        # TODO: Remove project logs (when done)
        # TODO: Remove project backups (when done)
    
    end
    
    # Connect to the terminal of one of the project containers.
    def run_connect()

        @project = Project.new()

        if !ARGV[1].nil?
            container = ARGV[1]
        else
            container = self.project.name + '-app'
        end
        
        system("docker exec -it #{container} bash")
        
    end
    
    # Run the initial setup scripts.
    def run_setup()

        # Create the quick-dev network.
        self.say("Creating quick-dev-network...")
        system("docker network create quick-dev-network | tee -a #{self.log}")

        # Create any core local images we will build from.
        self.say("Building local php-fpm image...")
        system("docker build -t quick-dev:php ./.docker/images/php-fpm")
    
    end
    
    # Start the project containers.
    def run_up()

        @project = Project.new()

        # Define additional arguments which can be passed to the `up` command.
        options = {}
        OptionParser.new do |opts|
            opts.banner = "Usage: qd add [options]"
            opts.on('-r', '--rebuild', 'Rebuild the docker image(s)') { options[:rebuild] = 'rebuild' }
            opts.on('-d', '--install-debug', 'Install debugging packages (Run first time you up the project)') { options[:debug] = 'debug' }
        end.parse!
        
        # Make sure the docker-compose file has been created by the `add` command.
        if !File.exist?(self.project.dir + '/docker-compose.yml')
           abort("No docker-compose.yml file found in #{self.project.dir}. Please run `qd add` to build the project first.") 
        end
        
        self.say("Setting up (#{self.project.name}) development environment...")
                
        # Create core network if it doesn't exist.
        system("docker network inspect #{QUICK_DEV_NETWORK} >/dev/null 2>&1 || (echo 'Creating quick-dev network:' && docker network create #{QUICK_DEV_NETWORK})")

        # Bring up core quick-dev containers.
        system("docker compose -f #{QUICK_DEV_PATH}/docker-compose.yml up -d")
        
        # Rebuild the project images if requested.
        if options[:rebuild]
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

        self.say("====================")
        self.say("Site will be rendered at: #{self.project.url}")
        self.say("ACTION REQUIRED - Please add the following to your config/index page: `require_once './.debug/autoload.php';`")
        self.say("====================")
        self.say("Services:")
        self.say("🗄️   Adminer: http://adminer.#{self.project.hostname}.localhost:8080?server=#{self.project.name}-db&username=user&db=main")
        self.say("🐞   Buggregator: http://buggregator.#{self.project.hostname}.localhost:8000")
        self.say("====================")
    
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
            opts.banner = "Usage: qd stop [options]"
            opts.on('-a', '--all', 'Destroy all the core quick-dev containers as well') { options[:all] = true }
        end.parse!
    
        # Stop the core quick-dev containers.
        if options[:all]
            system("docker compose -f #{QUICK_DEV_PATH}/docker-compose.yml down")
        end
        
        system("docker compose down")
       
    end
    
    # Add the site to Quick-Dev
    def run_add()

        @project = Project.new()

        # Find all the global templates to be copied across.
        Dir.glob(QUICK_DEV_PATH + '/.docker/templates/*.template').each do |file_name|
            self.copy_template(file_name)
        end

        # Then any project type specific ones.
        Dir.glob(QUICK_DEV_PATH + '/.docker/templates/' + self.project.type + '/*.template').each do |file_name|
            self.copy_template(file_name)
        end

        # Run any git patches which are required.
        Dir.glob(QUICK_DEV_PATH + '/.docker/templates/' + self.project.type + '/*.patch').each do |file_name|
            self.apply_patch(file_name)
        end
        
        self.say("Added #{self.project.name} (#{self.project.image}) to quick-dev")
        self.say("Run `qd up` to start the project")
    
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
            '%project.port%' => self.project.port,
            '%project.path%' => self.project.path,
            '%project.url%' => self.project.url,
            '%project.uri%' => self.project.uri,
            '%project.working_dir%' => self.project.working_dir,
            '%root%' => QUICK_DEV_PATH,
            '%context%' => '',
        }

        # Work out if we need the build context or not in the docker-compose file.
        image_path = QUICK_DEV_PATH + '/.docker/images/' + self.project.image
        if File.directory?(image_path)
           replace_map['%context%'] = "
        build:
            context: #{image_path}"
        end

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
        
        # Copy the file into the site directory.
        FileUtils.cp(file_name, new_file_name)
        
        # This makes the replacements in the file. Not entirely sure how it works.
        File.write(new_file_name, File.open(new_file_name, &:read).gsub(re, replace_map))

        self.say("#{file_name} ==> #{new_file_name}")

        # If it's the Caddy template, move it into the .docker/caddy directory as well, to be loaded into caddy container.
        if File.basename(file_name) == 'caddy.template'
            caddy_path = QUICK_DEV_PATH + '/.docker/caddy/' + self.project.name + '.caddy'
            FileUtils.cp(new_file_name, caddy_path)
            self.say("#{file_name} ==> #{caddy_path}")
        end

    end

end