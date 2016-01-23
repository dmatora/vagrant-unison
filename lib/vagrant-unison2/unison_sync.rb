module VagrantPlugins
  module Unison
    module UnisonSync
      def execute_sync_command(machine)
        unison_paths = UnisonPaths.new(@env, machine)
        guest_path = unison_paths.guest
        host_path = unison_paths.host

        @env.ui.info "Unisoning changes from {host}::#{host_path} --> {guest VM}::#{guest_path}"

        # Create the guest path
        machine.communicate.sudo("mkdir -p '#{guest_path}'")
        machine.communicate.sudo("chown #{machine.ssh_info[:username]} '#{guest_path}'")

        ssh_command = SshCommand.new(machine, unison_paths)
        shell_command = ShellCommand.new(machine, unison_paths, ssh_command)

        yield shell_command
      end
    end
  end
end
