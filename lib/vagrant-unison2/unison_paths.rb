module VagrantPlugins
  module Unison
    class UnisonPaths
      def initialize(env, machine)
        @env = env
        @machine = machine
      end

      def guest
        @machine.config.unison.guest_folder
      end

      def host
        @host ||= begin
          path = File.expand_path(@machine.config.unison.host_folder, @env.root_path)

          # Make sure there is a trailing slash on the host path to
          # avoid creating an additional directory with rsync
          path = "#{path}/" if path !~ /\/$/
        end
      end
    end
  end
end
