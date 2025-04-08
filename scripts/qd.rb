require 'fileutils'
require 'json'
require 'optparse'
require 'yaml'
require 'tty-markdown'
require 'tty-prompt'
require_relative 'project.rb'
require_relative 'const.rb'
Dir["#{File.dirname(__FILE__)}/commands/*.rb"].each {|file| require file }

# Main quick-dev class
class QuickDev

    # Attributes which can be accessed from this object.
    attr_accessor :project, :log, :prompt

    # Initialise an instance of the object
    # @return [QuickDev]
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

    # Run one of the built-in commands
    def run()

        # The command is the first argument to the script.
        # Everything else is considered arguments to that command.
        command = ARGV[0]

        case command

            when 'version'
                self.run_version()
            when 'help'
                self.run_help()
            when 'config'
                self.run_config()
            when 'build'
                self.run_build()
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
            when 'services'
                self.run_services()
            when 'backup'
                self.run_backup()
            when 'restore'
                self.run_restore()
            when 'dashboard'
                self.run_dashboard()
            when 'test'
                QuickDev.get_apps()
            else
                self.run_cmd()

        end

    end

    def run_dashboard

        # Define additional arguments which can be passed to the command.
        options = {}
        OptionParser.new do |opts|
            opts.banner = "Usage: qd dashboard [options]"
            opts.on('-s', '--stop', 'Stop the dashboard') { options[:stop] = 'stop' }
            opts.on('-d', '--detach', 'Do not open the web browser when the dashboard starts') { options[:detach] = true }
        end.parse!

        if options[:stop] === "stop"
            system("pid=$(lsof -i :4567 | grep ruby | awk '{print $2}'); kill $pid;")
        else
            system("ruby #{QUICK_DEV_PATH}/core/server.rb > /dev/null 2>&1 &")
            if options[:detach].nil?
                self.open("http://127.0.0.1:4567/")
            end
        end

    end

    # Check the version of Quick-Dev you are running.
    def run_version
        self.say("Quick-Dev #{QUICK_DEV_VERSION}")
        self.say("Made by Conn Warwicker")
        self.say("For any issues or feature requests, see: https://github.com/cwarwicker/quick-dev)")
    end

    # Display the help information
    def run_help()

        puts <<-HELP
            Usage:          qd [command] [arguments]

            help            Displays this help information
            version         Displays the version of Quick-Dev you are running
            config          Configures the project with the services you require
                            [-p|--preset] Choose from a preset configuration
            up              Starts the project containers
                            [-r|--rebuild] Rebuild the images
                            [-d|--debug] Install the composer packages required for buggregator service
            stop            Stops the project containers
                            [-a|--all] Includes the core quick-dev system containers
            destroy         Stops and deletes the project containers
                            [-a|--all] Includes the core quick-dev system containers
            remove          Completely remove the project from quick-dev
            connect         Opens terminal connection to a project container (default: "app" or first service found)
                            [name] Specific container to connect to
            services        Lists all running services in the project and their endpoints
            dashboard       Starts the Quick-Dev dashboard and opens it in your web browser
                            [-s|--stop] Stop the dashboard if it is running
            backup          Backup the application database
                            [-u|--user] The database user with backup permissions (defualt: user)
                            [-p|--password] The database user's password (default: password)
                            [-d|--db] The database name (default: main)
            <x>             Runs a project-specific command.
                            [command] The command to run. E.g. `artisan tinker` (laravel) or `purge` (moodle)
            cmd             Run any arbitrary command on the application console
                            [command] The command to run. E.g. `echo 'Hello World'`

        HELP

    end

    # Get an instance of a class, given its name
    # @param [String] class_name
    # @return [Object|false]
    def get_class(class_name)

       # If the class exists return a new instance of it. Else return false.
       return Module.const_get(class_name).new
       rescue NameError
           return false

    end

    # Check if we are currently within an apps project directory.
    # @return [Boolean]
    def self.is_in_app_dir()
        return Dir.pwd.start_with?(QUICK_DEV_PATH + '/apps/')
    end

    # Open site in web browser
    def open(url)

        if RUBY_PLATFORM =~ /linux/
            # Check if running under WSL
            if File.exist?('/proc/version') && File.read('/proc/version').downcase.include?('microsoft')
              # Running on WSL
              system("wslview '#{url}'") || system("powershell.exe Start-Process '#{url}'")
            else
              # Native Linux
              system("xdg-open '#{url}'") || puts("Please open this URL manually: #{url}")
          end
        else
            # Fallback for unsupported platforms
            puts "Only linux is supported. Please open this URL manually: #{url}"
        end

    end

    # Backup the attached database
    def run_backup()

        # Define additional arguments which can be passed to the `backup` command.
        options = {'user': 'user', 'password': 'password', 'db': 'main', 'service': 'db'}
        OptionParser.new do |opts|
            opts.banner = "Usage: qd backup [options]"
            opts.on('-u=user', '--user=user','Which database user to use (Default: `user`)')
            opts.on('-p=password', '--password=password', 'The user\'s password (Default: `password`)')
            opts.on('-d=database', '--db=database', 'Which database to backup (Default: `main`)')
            opts.on('-s=service', '--service=name', 'Which service contains the database? (Default: `db`)')
        end.parse!(into: options)

        # Load up what info we can from the dir.
        @project = Project.load()

        # Work out the container name.
        container = "#{self.project.name}-#{options[:service]}"

        # Do we have that service?
        unless self.project.services.key?(options[:service])
            abort("Service (#{options[:service]}) does not exist on this project")
        end

        # Work out the database type.
        type = self.project.services[options[:service]][:type]

        file_name = QUICK_DEV_PATH + '/backups/' + self.project.name + '-' + options[:db] + '-' + Time.now.strftime("%Y-%m-%d")

        if type === 'mariadb'
            file_name = file_name + '.sql'
            system("docker exec -it #{container} mariadb-dump -u #{options[:user]} -p#{options[:password]} --databases #{options[:db]} > #{file_name}")
        elsif type ==='mysql'
            file_name = file_name + '.sql'
            system("docker exec -it #{container} bash -c 'export MYSQL_PWD=#{options[:password]}; mysqldump -u #{options[:user]} --databases #{options[:db]} --no-tablespaces' > #{file_name}")
        elsif type === 'postgres'
            file_name = file_name + '.pgdump'
            local_file = '/tmp/' + File.basename(file_name)
            system("docker exec -it #{container} bash -c 'PGPASSWORD=#{options[:password]} pg_dump -Fc -U #{options[:user]} -d #{options[:db]} > #{local_file}'")
            system("docker cp #{container}:#{local_file} #{file_name}")
        end

        self.say("File created: #{file_name}")

    end

    # Restore a database dump to the database container
    def run_restore()

        # Define additional arguments which can be passed to the `restore` command.
        options = {'user': 'user', 'password': 'password', 'db': 'main', 'service': 'db'}
        OptionParser.new do |opts|
            opts.banner = "Usage: qd restore [options]"
            opts.on('-u=user', '--user=user','Which database user to use (Default: `user`)')
            opts.on('-p=password', '--password=password', 'The user\'s password (Default: `password`)')
            opts.on('-d=database', '--db=database', 'Which database to backup (Default: `main`)')
            opts.on('-s=service', '--service=name', 'Which service contains the database? (Default: `db`)')
        end.parse!(into: options)

        # Load up what info we can from the dir.
        @project = Project.load()

        # Work out the container name.
        container = "#{self.project.name}-#{options[:service]}"

        # Do we have that service?
        unless self.project.services.key?(options[:service])
            abort("Service (#{options[:service]}) does not exist on this project")
        end

        type = self.project.services[options[:service]][:type]
        file_name = ARGV[1]

        unless file_name
            abort("First argument must be the dump file to restore")
        end

        if type === 'mariadb'
            system("docker exec -i #{container} bash -c 'exec mariadb -u #{options[:user]} -p#{options[:password]}' < #{file_name}")
        elsif type ==='mysql'
            system("cat #{file_name} | docker exec -i #{container} bash -c 'export MYSQL_PWD=#{options[:password]}; mysql -u #{options[:user]}'")
        elsif type === 'postgres'
            system("docker cp #{file_name} #{self.project.name}-db:/tmp")
            system("docker exec -i #{container} bash -c 'dropdb #{options[:db]} -U #{options[:user]}'")
            local_file = '/tmp/' + File.basename(file_name)
            system("docker exec -i #{container} bash -c 'pg_restore -C -U #{options[:user]} -d postgres #{local_file}'")
        end

    end

    def run_config_preset()

        # Load the presets.
        presets = JSON.parse(File.read(QUICK_DEV_PATH + '/.docker/presets.json'))
        choice = self.prompt.select("Which preset do you want to use?") do |menu|

            presets.each do |key, item|
                item.each do |v, obj|
                    obj['type'] = key
                    menu.choice key + ' // ' + v, obj
                end
            end

        end

        # Build the cfg.yaml from the preset.
        data = {}
        data[:services] = {}
        data[:services]['app'] = {
          'type': choice['type'],
          'image': choice['app']['image'],
          'args': {},
          'ports': [],
          'hooks': {}
        }

        if choice['app']['args']
            choice['app']['args'].each do |arg, value|
                data[:services]['app'][:args][arg] = value
            end
        end

        if choice['app']['ports']
            data[:services]['app'][:ports] = choice['app']['ports']
        end

        if choice['app']['hooks']
            data[:services]['app'][:hooks] = choice['app']['hooks']
        end

        if choice['app']['patches']
            data[:services]['app'][:patches] = choice['app']['patches']
        end

        # If a /mnt directory exists within the template directory, add that as a mount volume.
        mnt = QUICK_DEV_PATH + '/.docker/templates/' + data[:services]['app'][:type] + '/mnt'
        if Dir.exist?(mnt)
            data[:services]['app'][:volumes] = [mnt + ':/mnt']
        end

        if choice['db']
            split = choice['db']['image'].split(':')
            data[:services]['db'] = {
              'type': split[0],
              'version': split[1],
              'image': choice['db']['image']
            }
        end

        if choice['cache']
            split = choice['cache']['image'].split(':')
            data[:services]['cache'] = {
              'type': split[0],
              'version': split[1],
              'image': choice['cache']['image']
            }
        end

        config_file = project.dir + '/cfg.yaml'
        self.save_config(data, config_file)

    end

    # Run the config command on your project.
    def run_config()

        # Load up what info we can from the dir.
        @project = Project.create()

        options = {'preset': false}
        OptionParser.new do |opts|
            opts.banner = "Usage: qd config [options]"
            opts.on('-p', '--preset', 'Select a preset configuration instead of rolling your own')
        end.parse!(into: options)

        # Check if the config file already exists.
        config_file = project.dir + '/cfg.yaml'
        docker_file = project.dir + '/docker-compose.yml'
        if File.exist?(config_file)
            if self.prompt.select("Existing config file(s) found. Do you wish to make a backup?", %w(yes no)) === 'yes'
                FileUtils.cp(config_file, config_file + '.backup')
                FileUtils.cp(docker_file, docker_file + '.backup') if File.exist?(docker_file)
            end
        end

        # Delete the config files.
        File.delete(config_file) if File.exist?(config_file)
        File.delete(docker_file) if File.exist?(docker_file)

        # If we want a preset, call that method instead.
        if options[:preset]
            return self.run_config_preset()
        end

        # Load the services JSON.
        services = JSON.parse(File.read(QUICK_DEV_PATH + '/.docker/services.json'))

        # Start building the config Hash to create the yaml file.
        data = {}
        data[:services] = {}

        # No longer hard-coding services like "app". Now it asks how many you want and lets you name them.
        reserved_names = ['db', 'cache']
        num_services = self.prompt.ask("How many application services do you need?", convert: :int, default: 1)
        my_services = []

        num_services.times do |i|
            service_name = self.prompt.ask("Service [#{i + 1}] name (e.g. 'app', 'backend', etc...)", required: true, default: "app") do |p|
                p.validate ->(input) { input =~ /^[a-z]+$/ and not my_services.include?(input) and not reserved_names.include?(input) }
                p.messages[:valid?] = "Service name must be lowercase [a-z] and not one of the reserved names: db, cache"
            end
            my_services.push(service_name)
        end


        # Loop through the services.
        my_services.each do |name|

            # What type of application are we running?
            data[:services][name] = {}
            data[:services][name][:type] = self.prompt.select("#{name} // What type of application will you be running?") do |menu|

                services['apps'].each do |obj|
                    menu.choice obj['name'].capitalize, obj['name']
                end

            end

            # Next, do we want to use a preset image or define our own?
            which_image = self.prompt.select("#{name} // Which image do you want to use?") do |menu|

                menu.choice :custom

                i = 2
                services['apps'].each do |obj|
                    if obj.key?('image')
                        menu.choice obj['image'], obj['image']
                        if obj['name'] == data[:services][name][:type]
                            menu.default i
                        end
                        i += 1
                    end
                end

            end

            # If they asked for a custom image, let them input it.
            if which_image === 'custom'
                data[:services][name][:image] = self.prompt.ask("Please input the docker image to pull for this application: ")
            else
                data[:services][name][:image] = which_image
                # Are there any image args we need to gather?
                data[:services][name][:args] = {}
                services['apps'].each do |obj|
                    if obj['name'] == data[:services][name][:type] and obj.key?('args')
                        obj['args'].each do |arg|
                            data[:services][name][:args][arg['name']] = self.prompt.ask("Image argument (#{arg['name']}): ", default: arg['default'])
                        end
                    end
                end
            end

            # What port(s) need to be mapped for this application?
            default_ports = []
            services['apps'].each do |obj|
                if obj['name'] == data[:services][name][:type] and obj.key?('ports')
                    default_ports = obj['ports']
                end
            end

            ports = self.prompt.ask("#{name} // Which port(s) need to be mapped for this application? (host:container,host:container,...)", default: default_ports.join(","))
            data[:services][name][:ports] = ports.split(',')

            # Add any additional required services linked to this type. E.g. Caddy for most web-based app types.
            services['apps'].each do |obj|
                if obj['name'] == data[:services][name][:type] and obj.key?('requires')
                    data[:services][name][:requires] = []
                    obj['requires'].each do |requires|
                        data[:services][name][:requires].push(requires)
                    end
                end
            end

            # Hooks.
            # Do we have any default hooks for the application type?
            services['apps'].each do |obj|
                if obj['name'] == data[:services][name][:type] and obj.key?('hooks')
                    obj['hooks'].each do |type, script|
                        data[:services][name][:hooks] = {type => script}
                    end
                end
            end

            any_hooks = self.prompt.yes?("#{name} // Do you want to add custom hooks to this service? (This will override any preset hooks for the application type)", default: false)
            if any_hooks

                # Select the hook types they want.
                hooks = self.prompt.multi_select("#{name} // Which hooks do you want to add to the service?") do |menu|
                    # menu.choice "Init - Container script. Run after first time containers are started.", 'init'
                    menu.choice "Pre-Up - Host script. Run just before the containers are started.", 'pre_up'
                    menu.choice "Post-Up - Container script. Run just after the containers are started.", 'post_up'
                    menu.choice "Pre-Stop - Container script. Run just before the containers are stopped.", 'pre_stop'
                    menu.choice "Post-Stop - Host script. Run just after the containers are stopped.", 'post_stop'
                end

                # Enter the hook script path.
                if hooks
                    data[:services][name][:hooks] = {}
                    hooks.each do |hook|
                        data[:services][name][:hooks][hook] = []
                        data[:services][name][:hooks][hook].push(self.prompt.ask("Enter the path of the script for this hook (#{hook}): "))
                    end
                end

            end

            data[:services][name][:local_dir] = self.prompt.ask("#{name} // What directory do you want mounted to the service container?", default: "./")

        end

        # Choose the other services required for the app.
        other_services = self.prompt.multi_select("Which other services do you need?") do |menu|
           menu.default 1,2
           menu.choice :Database, 'db'
           menu.choice :Caching, 'cache'
        end

        # If we need a DB, what engine and version do we want?
        if other_services.include?('db')

            data[:services]['db'] = {}

            # Get the DB engine.
            data[:services]['db'][:type] = self.prompt.select("Choose a database engine") do |menu|
                services['db'].each do |obj|
                    menu.choice obj['name']
                end
            end

            # Get the version.
            which_version = self.prompt.select("Choose a #{data[:services]['db'][:type]} version") do |menu|
                services['db'].each do |obj|
                    if obj['name'] === data[:services]['db'][:type]
                        obj['versions'].each do |v|
                            menu.choice v
                        end
                        menu.choice :custom
                    end
                end
            end

            # If we chose custom, ask for a version tag.
            if which_version === 'custom'
                data[:services]['db'][:version] = self.prompt.ask("Which #{data[:services]['db'][:type]} version would you like? ")
            else
                data[:services]['db'][:version] = which_version
            end

            # Image
            data[:services]['db'][:image] = data[:services]['db'][:type] + ':' + data[:services]['db'][:version]

        end

        # If we want a caching service.
        if other_services.include?('cache')

            data[:services]['cache'] = {}

            # Get the cache engine.
            data[:services]['cache'][:type] = self.prompt.select("Choose a caching system") do |menu|
                services['cache'].each do |obj|
                    menu.choice obj['name']
                end
            end

            # Get the version.
            which_version = self.prompt.select("Choose a #{data[:services]['cache'][:type]} version") do |menu|
                services['cache'].each do |obj|
                    if obj['name'] === data[:services]['cache'][:type]
                        obj['versions'].each do |v|
                            menu.choice v
                        end
                        menu.choice :custom
                    end
                end
            end

            # If we chose custom, ask for a version tag.
            if which_version === 'custom'
                data[:services]['cache'][:version] = self.prompt.ask("Which #{data['cache'][:type]} version would you like? ")
            else
                data[:services]['cache'][:version] = which_version
            end

            # Image
            data[:services]['cache'][:image] = data[:services]['cache'][:type] + ':' + data[:services]['cache'][:version]

        end

        self.save_config(data, config_file)

    end

    # Save the Hash of config data to the project config file
    def save_config(data, config_file)

        # Save the config.
        File.write(config_file, data.to_yaml)

        # Reload the project.
        @project = Project.load()

        # Find all the global templates to be copied across.
        Dir.glob(QUICK_DEV_PATH + '/.docker/templates/*.template').each do |file_name|
            self.copy_template(file_name)
        end

        # Then any project type specific ones for each service.
        project.services.each do |service, service_data|

            Dir.glob(QUICK_DEV_PATH + '/.docker/templates/' + service_data[:type] + '/*.template').each do |file_name|
                self.copy_template(file_name)
            end

            # Apply any patches required.
            unless service_data[:patches].nil?
                service_data[:patches].each do |patch|
                   file = QUICK_DEV_PATH + '/.docker/templates/' + service_data[:type] + '/' + patch + '.patch'
                   if File.exist?(file)
                       self.apply_patch(file)
                   end
                end
            end

        end

        # Then do we have any custom templates to copy from the project itself? This will override core ones if they have the same name.
        Dir.glob(project.dir + '/.templates/*.template').each do |file_name|
            self.copy_template(file_name)
        end

        self.say("Project configured (#{config_file}). Run `qd up` to bring up the containers.")

    end

    # Run any command you want on the container, assuming it exists.
    def run_cmd()

        command = ARGV[0]

        # Project must be loaded.project_class
        @project = Project.load()

        main = self.project.get_main_service
        project_class = self.get_class(main[:type].capitalize)
        all_class = self.get_class('All')
        if project_class and project_class.respond_to?(command)
            container = self.project.name + '-app'
            project_class.send(command, container, self)
        elsif all_class and all_class.respond_to?(command)
            container = self.project.name + '-app'
            all_class.send(command, container, self)
        else
            self.say('Invalid command ('+command+') for project type ('+main[:type]+')')
        end

    end

    # Get the status (running/stopped) of a docker container
    # @param [String] container
    # @return [String]
    def self.get_service_status(container)
        status = `docker inspect -f '{{.State.Running}}' #{container} 2>/dev/null`
        return (status.include?('true')) ? 'active' : 'inactive'
    end

    def self.get_service_info(type, project = nil)

        if project.nil?
            project = Project.load()
        end

        services = []

        if type === 'project' and !project.services.nil?

            # Loop through the project services.
            project.services.each do |name, service|

                get_service = -> (name, service) {

                    url = ''
                    status = QuickDev.get_service_status(project.name + '-' + "#{name}").strip

                    # Get url of "main" application service.
                    if service[:main]
                        url = project.get_url()
                    end

                    return {
                        :name => "#{project.name}-#{name}",
                        :type => service[:type],
                        :status => status,
                        :url => url,
                    }

                }

                if service.is_a?(Array)
                    service.each do |s|
                        services.push(get_service.call(s[:type].to_sym, s))
                    end
                else
                    services.push(get_service.call(name, service))
                end

            end

        elsif type === 'core'

            if !project.services.nil? and !project.services['db'].nil?
                adminer_url = "http://adminer.localhost:8080?server=#{project.name}-db&username=user&db=main"
            else
                adminer_url = nil
            end

            # These can be hard-coded as core services will be hard defined in the docker-compose anyway.
            services.push({:name => 'quick-dev-adminer', :type => 'core', :status => QuickDev.get_service_status('quick-dev-adminer').strip, :url => adminer_url})
            services.push({:name => 'quick-dev-buggregator', :type => 'core', :status => QuickDev.get_service_status('quick-dev-buggregator').strip, :url => "http://buggregator.localhost:8000"})
            services.push({:name => 'quick-dev-caddy', :type => 'core', :status => QuickDev.get_service_status('quick-dev-caddy').strip, :url => nil})
            services.push({:name => 'quick-dev-selenium-hub', :type => 'core', :status => QuickDev.get_service_status('quick-dev-selenium-hub').strip, :url => "http://selenium.localhost:4444"})
            services.push({:name => 'quick-dev-chrome', :type => 'core', :status => QuickDev.get_service_status('quick-dev-chrome').strip, :url => "http://selenium.localhost:7901?autoconnect=1&resize=scale&password=secret"})
            services.push({:name => 'quick-dev-firefox', :type => 'core', :status => QuickDev.get_service_status('quick-dev-firefox').strip, :url => "http://selenium.localhost:7902?autoconnect=1&resize=scale&password=secret"})

        end

        return services

    end

    # Run the services command to view services and their status/info
    def run_services()

        @project = Project.load()

        delim = "{@}"
        content = "PROJECT SERVICES (#{self.project.name})\n\n"
        content = content + "NAME#{delim}TYPE#{delim}STATUS#{delim}URL\n"

        info = QuickDev.get_service_info('project')
        info.each do |i|
            content = content + "#{i[:name]}#{delim}#{i[:type]}#{delim}#{i[:status]}#{delim}#{i[:url]}\n"
        end

        content = content + "\n----------\n"
        content = content + "CORE SERVICES\n\n"
        content = content + "NAME#{delim}STATUS#{delim}URL\n"

        info = QuickDev.get_service_info('core')
        info.each do |i|
            content = content + "#{i[:name]}#{delim}#{i[:type]}#{delim}#{i[:status]}#{delim}#{i[:url]}\n"
        end

        system("echo '#{content}' | column -t -s'#{delim}'")

    end

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

    # Connect to the terminal of one of the project containers (main app container by default)
    def run_connect()

        @project = Project.load()

        if !ARGV[1].nil?
            container = ARGV[1]
        else
            main = self.project.get_main_service(name: true)
            container = self.project.name + '-' + main
        end

        system("docker exec -it #{container} bash")

    end

    # Build the docker-compose file and the containers, but don't bring them up yet
    def run_build()

        @project = Project.load()

        # Define additional arguments which can be passed to the `up` command.
        options = {}
        options[:fileonly] = false

        OptionParser.new do |opts|
            opts.banner = "Usage: qd build [options]"
            opts.on('-f', '--file-only', 'Only build the docker-compose file, not the images') { options[:fileonly] = true }
        end.parse!

        # Delete the docker-compose if it exists
        docker_file = project.dir + '/docker-compose.yml'
        File.delete(docker_file) if File.exist?(docker_file)

        # Build the docker-compose file from scratch.
        project.build_docker_compose()

        # Build images and containers.
        if not options[:fileonly]
            system("docker compose pull")
            system("docker compose build --no-cache")
        end

    end

    # Start the project containers.
    def run_up()

        @project = Project.load()

        # Define additional arguments which can be passed to the `up` command.
        options = {}
        OptionParser.new do |opts|
            opts.banner = "Usage: qd up [options]"
            opts.on('-r', '--rebuild', 'Rebuild the docker image(s)') { options[:rebuild] = 'rebuild' }
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


        # Run any service pre-up hooks.
        self.execute_hooks('pre_up')

        # Bring up project containers.
        system("docker compose up -d")

        # Run any service post-up hooks or init hooks.
        self.execute_hooks('post_up')

        self.say("\n")
        self.run_services()

    end

    # Execute hook on the host or service container, depending on the hook type
    # @param [String] hook_type
    def execute_hooks(hook_type)

        self.project.services.each do |service, type|
            unless !(type.is_a?(Hash)) or type[:hooks].nil? or type[:hooks][hook_type].nil?
                type[:hooks][hook_type].each do |script|
                    if hook_type === 'pre_up' or hook_type === 'post_stop'
                        self.say("Running {#{hook_type}} hook on host: `#{script}`")
                        system(script)
                    elsif hook_type === 'post_up' or hook_type === 'pre_stop'
                        self.say("Running {#{hook_type}} hook on service (#{service}): `#{script}`")
                        container = self.project.name + '-' + service.to_s
                        system("docker exec -it #{container} #{script}")
                    end
                end
            end
        end

    end

    # Stop the project containers.
    def run_stop()

        @project = Project.load()

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

        self.execute_hooks('pre_stop')

        # Stop the project containers.
        system("docker compose stop")

        self.execute_hooks('post_stop')

    end

    # Destroy the project containers.
    def run_destroy()

        @project = Project.load()

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

        # Remove project containers and images.
        system("docker compose down --rmi all")

    end

    # Apply a git patch file
    # @param [String] patch_name
    def apply_patch(patch_name)
        self.say("Applying git patch #{patch_name}")
        system("git apply #{patch_name}")
    end

    # Copy template files into the project directory
    # @param [String] file_name The template file to copy
    # @param [String|nil] project_path If specified, it will be copied to this path.
    def copy_template(file_name, project_path = nil)

        # Replace placeholders with project values in the copied files.
        replace_map = {
            '%project.name%' => self.project.name,
            '%project.url%' => self.project.url,
            '%project.uri%' => self.project.uri,
            '%project.working_dir%' => self.project.working_dir,
            '%project.db%' => self.project.db,
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

            # Moodle/Totara have some bits that need changing.
            main = self.project.get_main_service
            if ['moodle', 'totara'].include?(main[:type])
                replace_map['%project.db%'] = 'pgsql' if self.project.db == 'postgres'
                replace_map['%project.db%'] = 'mysqli' if self.project.db == 'mysql'
            end

            # Copy the file into the site directory.
            FileUtils.cp(file_name, new_file_name)

            # This makes the replacements in the file. Not entirely sure how it works.
            File.write(new_file_name, File.open(new_file_name, &:read).gsub(re, replace_map))

            self.say("#{file_name} ==> #{new_file_name}")

        end

    end

    def self.get_apps()

        apps = []

        # Find any projects we have configured in the apps directory.
        Dir.glob(QUICK_DEV_PATH + '/apps/*').each do | p |
            if File.directory?(p)

                app = {}

                # Get the project name from the path.
                name = Pathname.new(p).basename.to_s

                app[:name] = name

                # Load the cfg.yaml file if it exists.
                project = Project.get(name, p)

                app[:config] = project.config

                # If there is no config, it's not a quick-dev project so ignore it.
                if app[:config].nil?
                    next
                end

                # Check the status of the project by checking its main application container.
                main = project.get_main_service(name: true)
                app[:status] = QuickDev.get_service_status(name + '-'+ main)

                # Get the services for this application.
                app[:services] = QuickDev.get_service_info('project', project) + QuickDev.get_service_info('core', project)

                # Get the git branch that is checked out.
                branch = nil
                head = p + "/.git/HEAD"
                if File.exist?(head)
                    branch = File.read(head).split("/").last
                end
                app[:branch] = branch

                apps.push(app)

            end
        end

        return apps

    end

end