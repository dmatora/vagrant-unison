module VagrantPlugins
  module Unison
    class SshCommand
      def initialize(machine)
        @machine = machine
      end

      def command
        %W(
          -p #{@machine.ssh_info[:port]}
          #{proxy_command}
          -o StrictHostKeyChecking=no
          -o UserKnownHostsFile=/dev/null
          #{key_paths}
        ).compact.join(' ')
      end

      def uri(unison_paths)
        username = @machine.ssh_info[:username]
        host = @machine.ssh_info[:host]

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
