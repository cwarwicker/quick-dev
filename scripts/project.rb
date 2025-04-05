require 'dotenv'
require 'pathname'
require 'socket'
require 'yaml'
require 'active_support/core_ext/hash/keys'
require_relative 'const.rb'

class Project

    attr_accessor :services, :config, :type, :name, :image, :image_args, :ports, :hooks, :patches, :volumes, :url, :uri, :db, :dir, :working_dir, :requires

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

      # Load the project config.
      config_file = project.dir + '/cfg.yaml'
      if File.exist?(config_file)
          project.config = YAML.load_file(config_file)
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
          project.services[service][:working_dir] = '/app'
          project.services[service][:local_dir] = data[:local_dir]

        end

        project.uri = project.name + '.localhost'
        project.url = 'https://' + project.name + '.localhost'
        project.db = project.config[:db][:type] if !project.config[:db].nil?

        return project

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

    end

    def build_docker_compose()

        data = {}
        data['services'] = {}

        self.services.each do |name, service|

          data['services'][name] = {
            'container_name': self.name + '-' + name,
            'volumes': [
              service[:local_dir] + ':' + service[:working_dir]
            ],
            'networks': [
              'quick-dev-network'
            ],
            'stdin_open': true,
            'extra_hosts': [
              'host.docker.internal:host-gateway'
            ],
          }

          if service[:volumes]
              data['services'][name][:volumes] = data['services'][name][:volumes] + service[:volumes]
          end

          if self.ports
              data['services'][name]['ports'] = service[:ports]
          end

          # If we are using a quick-dev image, we need a build context.
          if service[:image].start_with?('quick-dev:')

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

        end

        # Database.
        if self.config[:db]

          data['services']['db'] = {
            'container_name': self.name + '-db',
            'stdin_open': true,
            'image': self.config[:db][:type] + ':' + self.config[:db][:version],
            'networks': [
              'quick-dev-network'
            ]
          }

          # Read service-specific config to load in.
          service_config = JSON.parse(File.read(QUICK_DEV_PATH + '/.docker/services/' + self.config[:db][:type] + '.service'), {symbolize_names: true})
          data['services']['db'] = data['services']['db'].merge(service_config)

        end

        # Caching.
        if self.config[:cache]

          data['services']['cache'] = {
            'container_name': self.name + '-cache',
            'image': self.config[:cache][:type] + ':' + self.config[:cache][:version],
            'networks': [
              'quick-dev-network'
            ]
          }

          # Read service-specific config to load in.
          service_config = JSON.parse(File.read(QUICK_DEV_PATH + '/.docker/services/' + self.config[:cache][:type] + '.service'), {symbolize_names: true})
          data['services']['cache'] = data['services']['cache'].merge(service_config)

        end

        data['networks'] = {
          'quick-dev-network': {
            'external': true
          }
        }

        # Write the docker-compose file.
        File.write(self.dir + '/docker-compose.yml', data.deep_stringify_keys.to_yaml)

    end

    # Get the URL of the main application
    # This might sometimes return an invalid url if the application isn't web-based, but currently not got a way to define that.
    def get_url()

      url = "https://#{self.name}.localhost"

      if self.ports
        # Assumption is that the first port mapping is the main one.
        url = url + ':' + self.ports[0].split(':')[0]
      end

      return url

    end

end