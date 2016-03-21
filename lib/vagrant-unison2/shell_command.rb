module VagrantPlugins
  module Unison
    class ShellCommand
      def initialize machine, unison_paths, ssh_command
        @machine = machine
        @unison_paths = unison_paths
        @ssh_command = ssh_command
      end

      attr_accessor :batch, :repeat, :terse

      def to_a
        args.map do |arg|
          arg = arg[1...-1] if arg =~ /\A"(.*)"\z/
          arg
        end
      end

      def to_s
        args.join(' ')
      end

      private

      def args
        _args = [
          'unison',
          @unison_paths.host,
          @ssh_command.uri(@unison_paths),
          batch_arg,
          terse_arg,
          repeat_arg,
          ignore_arg,
          perms_arg,
          ['-sshargs', %("#{@ssh_command.ssh_args}")],
        ].flatten.compact
        _args
      end

      def batch_arg
        '-batch' if batch
      end

      def ignore_arg
        ['-ignore', %("#{@machine.config.unison.ignore}")] if @machine.config.unison.ignore
      end

      def perms_arg
        ['-perms', @machine.config.unison.perms] if @machine.config.unison.perms
      end

      def repeat_arg
        ['-repeat', @machine.config.unison.repeat] if repeat && @machine.config.unison.repeat
      end

      def terse_arg
        '-terse' if terse
      end
    end
  end
end
