require_relative 'moodle.rb'

class Totara < Moodle

    def initialize(data)
        @dir = './server'
        @cli_dir = './server'
    end

end
