require 'dotenv'
require 'pathname'
require 'socket'
require 'yaml'
require 'active_support/core_ext/hash/keys'
require_relative 'const.rb'

class Project
    
    ENV_FILE = '.quick-dev.env'
    
    attr_accessor :type, :name, :image, :image_args, :url, :uri, :dir, :working_dir

    # Create an instance of the Project class and bootstrap it with some data from the path.
    def self.create()
        project = Project.new
        project.bootstrap()
        return project
    end

    def self.load()

        project = Project.create()

        # Load the project config.
        config_file = project.dir + '/cfg.yaml'
        unless File.exist?(config_file)
            abort("Missing #{config_file}. Please run `qd config` to create it.")
        end

        config = YAML.load_file(config_file)

        project.type = config[:app][:type]
        project.image = config[:app][:image]
        project.image_args = config[:app][:args]
        project.working_dir = '/app'
        project.uri = project.name + '.localhost'
        project.url = 'https://' + project.name + '.localhost'

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
        data['services']['app'] = {
          'container_name': self.name + '-app',
          'image': self.image,
          'volumes': [
            './:' + self.working_dir
          ],
          'networks': [
            'quick-dev-network'
          ]
        }

        # If we are using a quick-dev image, we need a build context.
        if self.image.start_with?('quick-dev:')
          data['services']['app']['build'] = {
            'context': QUICK_DEV_PATH + '/.docker/images/app/' + self.image.delete_prefix('quick-dev:'),
            'args': self.image_args
          }
        end



        data['networks'] = {
          'quick-dev-network': {
            'external': true
          }
        }

        # Write the docker-compose file.
        File.write(self.dir + '/docker-compose.yml', data.deep_stringify_keys.to_yaml)

    end
    
end