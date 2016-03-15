module VagrantPlugins
  module Unison
    class SshCommand
      def initialize(machine)
        @machine = machine
      end

      def ssh
        %W(
          ssh
          #{@machine.config.unison.ssh_user}@#{@machine.config.unison.ssh_host}
          #{ssh_args}
        ).compact.join(' ')
      end

      def ssh_args
        %W(
          -p #{@machine.config.unison.ssh_port}
          #{proxy_command}
          -o StrictHostKeyChecking=no
          -o UserKnownHostsFile=/dev/null
          #{key_paths}
        ).compact.join(' ')
      end

      def uri(unison_paths)
        username = @machine.config.unison.ssh_user
        host = @machine.config.unison.ssh_host

        "ssh://#{username}@#{host}/#{unison_paths.guest}"
      end

      private

      def proxy_command
        command = @machine.ssh_info[:proxy_command]
        return nil unless command
        "-o ProxyCommand='#{command}'"
      end

      def key_paths
        @machine.ssh_info[:private_key_path].map { |p| "-i #{p}" }.join(' ')
      end
    end
  end
end
