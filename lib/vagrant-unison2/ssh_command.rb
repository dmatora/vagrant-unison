module VagrantPlugins
  module Unison
    class SshCommand
      def initialize(machine, unison_paths)
        @machine = machine
        @unison_paths = unison_paths
      end

      def command
        %W(
          -p #{ssh_info[:port]}
          #{proxy_command}
          -o StrictHostKeyChecking=no
          -o UserKnownHostsFile=/dev/null
          #{key_paths}
        ).compact.join(' ')
      end

      def uri
        username = ssh_info[:username]
        host = ssh_info[:host]

        "ssh://#{username}@#{host}/#{@unison_paths.guest}"
      end

      private

      def proxy_command
        command = ssh_info[:proxy_command]
        return nil unless command
        "-o ProxyCommand='#{command}'"
      end

      def ssh_info
        @machine.ssh_info
      end

      def key_paths
        ssh_info[:private_key_path].map { |p| "-i #{p}" }.join(' ')
      end
    end
  end
end
