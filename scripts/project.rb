require 'dotenv'
require 'pathname'
require 'socket'
require_relative 'const.rb'

class Project
    
    ENV_FILE = '.quick-dev.env'
    
    attr_accessor :type, :name, :image, :repo, :branch, :path, :port, :ip, :hostname, :built, :url, :dir
    
    def initialize()
        
        # Work out the project name from the path, as we want to be able to call commands from any subdir. 
        @name = Pathname(Dir.pwd.delete_prefix(QUICK_DEV_PATH + '/sites/')).parent.to_s
        
        # If we are already at the top level of the project, get the current dir name instead.
        if self.name == '.'
            self.name = File.basename(Dir.pwd) 
        end
        
        @dir = QUICK_DEV_PATH + '/sites/' + self.name
    
        # If the env file does not exist in this directory, copy it over and tell them to fill it out.
        unless File.exist?(self.dir + '/' + ENV_FILE)
            FileUtils.cp(QUICK_DEV_PATH + '/.env.dist', self.dir + '/' + ENV_FILE)
            abort("Please fill out the config in `#{ENV_FILE}` and run again.")
        end
    
        # Get some info from the server.
        @hostname = Socket.gethostname
        
        # Load the env variables into the project object.
        Dotenv.load(self.dir + '/' + ENV_FILE)
        @type = ENV['PROJECT_TYPE']
        @image = ENV['PROJECT_IMAGE']
        @port = ENV['PROJECT_PORT']
        
        # If any of the required info is missing, we cna go no further.
        if self.type.empty? || self.image.empty? || self.port.empty?
            abort("Missing required information in #{ENV_FILE}")
        end
        
        # Other variables about the project, not from env file.
        @url = 'http://' + self.name + '.' + self.hostname + '.dev.io:' + self.port
        
    end
    
end