require 'dotenv'
require 'pathname'
require 'socket'
require 'yaml'
require 'active_support/core_ext/hash/keys'
require_relative 'const.rb'

class Project

    attr_accessor :services, :config, :name, :uri, :url, :db, :dir, :working_dir, :path

    # Create an instance of the Project class and bootstrap it with some data from the path.
    def self.create()

        # Must be inside an app directory.
        unless QuickDev.is_in_app_dir()
          abort("Must be inside an app")
        end

        project = Project.new
        project.bootstrap()
        return project

    end

    def self.get(name, dir)

      project = Project.new
      project.name = name
      project.dir = dir
      project.working_dir = '/app'

      # Load the project config.
      config_file = project.dir + '/cfg.yaml'
      if File.exist?(config_file)
          project.config = YAML.load_file(config_file)
          load_services(project)
      else
        project.config = nil
      end

      return project

    end

    def self.load()

        project = Project.create()

        # Load the project config.
        config_file = project.dir + '/cfg.yaml'
        unless File.exist?(config_file)
            abort("Missing #{config_file}. Please run `qd config` to create it.")
        end

        project.config = YAML.load_file(config_file)
        load_services(project)

        project.uri = project.name + '.localhost'
        project.url = 'https://' + project.name + '.localhost'
        project.db = project.config[:db][:type] if !project.config[:db].nil?
        project.path = project.config[:path] if !project.config[:path].nil?

        return project

    end

    def self.load_services(project)

      project.services = {}
      project.config[:services].each do |service, data|

          project.services[service] = {}
          project.services[service][:type] = data[:type]
          project.services[service][:image] = data[:image]
          project.services[service][:image_args] = data[:args]
          project.services[service][:ports] = data[:ports] if !data[:ports].nil? and !data[:ports].empty?
          project.services[service][:requires] = data[:requires] if !data[:requires].nil? and !data[:requires].empty?
          project.services[service][:hooks] = data[:hooks] if !data[:hooks].nil? and !data[:hooks].empty?
          project.services[service][:patches] = data[:patches] if !data[:patches].nil? and !data[:patches].empty?
          project.services[service][:volumes] = data[:volumes] if !data[:volumes].nil? and !data[:volumes].empty?
          project.services[service][:working_dir] = project.working_dir
          project.services[service][:local_dir] = data[:local_dir]

          if service == project.config[:services].keys.first
              project.services[service][:main] = true
          else
              project.services[service][:main] = false
          end

        end

    end

    def bootstrap()

       # Work out the project name from the path, as we want to be able to call commands from any subdir.
       Pathname(Dir.pwd.delete_prefix(QUICK_DEV_PATH + '/apps/')).ascend do |value|
           @name = value.to_s
       end

       # If we are already at the top level of the project, get the current dir name instead.
       if self.name == '.'
           self.name = File.basename(Dir.pwd)
       end

       @dir = QUICK_DEV_PATH + '/apps/' + self.name
       @working_dir = '/app'

    end

    def build_docker_compose()

        data = {}
        data['services'] = {}

        self.services.each do |name, service|

            data['services'][name] = {
                'container_name': self.name + '-' + name,
                'networks': [
                  'quick-dev-network'
                ],
                'volumes': [],
                'stdin_open': true,
                'extra_hosts': [
                  'host.docker.internal:host-gateway'
                ],
            }

            if service[:local_dir] and service[:working_dir]
                data['services'][name][:volumes].push(service[:local_dir] + ':' + service[:working_dir])
            end

            if service[:volumes]
                data['services'][name][:volumes] = data['services'][name][:volumes] + service[:volumes]
            end

            if service[:ports]
                data['services'][name][:ports] = service[:ports]
            end

            # If we are using a quick-dev image, we need a build context.
            if service[:image] and service[:image].start_with?('quick-dev:')

                img = service[:image].delete_prefix('quick-dev:')
                stage = img.split(':')[-1]
                common = img.split(':')[0]

                data['services'][name]['build'] = {
                  'context': QUICK_DEV_PATH + '/.docker/images/' + common,
                  'target': stage,
                  'args': service[:image_args]
                }

                data['services'][name]['image'] = 'quick-dev:' + self.name + '-' + name

            else
                data['services'][name]['image'] = service[:image]
            end

            # Is there a service-specific config to load in?
            path = QUICK_DEV_PATH + '/.docker/services/' + service[:type] + '.service'
            if File.exist?(path)
                service_config = JSON.parse(File.read(path), {symbolize_names: true})
                data['services'][name] = data['services'][name].merge(service_config)
            end

        end

        data['networks'] = {
          'quick-dev-network': {
            'external': true
          }
        }

        # Write the docker-compose file.
        File.write(self.dir + '/docker-compose.yml', data.deep_stringify_keys.to_yaml)

    end

    # Assumption is that the first application service is the "main" one, which will be used for things like the url.
    def get_main_service(name = false)
        return name ? self.services.keys.first : self.services.values.first
    end

    # Get the URL of the main application
    # This might sometimes return an invalid url if the application isn't web-based, but currently not got a way to define that.
    def get_url()

      url = "https://#{self.name}.localhost"
      main = self.get_main_service()

      if main[:ports]
        # Assumption is that the first port mapping is the main one.
        port =  main[:ports][0].split(':')[0]
        if port != '80' and port != '443'
            url = url + ':' + main[:ports][0].split(':')[0]
        end
      end

      return url

    end

end