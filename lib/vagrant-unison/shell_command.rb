module VagrantPlugins
  module Unison
    class ShellCommand
      def initialize machine, paths, ssh_command
        @machine = machine
        @paths = paths
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
        [
          'unison',
          @paths.host,
          @ssh_command.uri,
          batch_arg,
          terse_arg,
          repeat_arg,
          ignore_arg,
          ['-sshargs', %("#{@ssh_command.command}")],
        ].flatten.compact
      end

      def batch_arg
        '-batch' if batch
      end

      def ignore_arg
        ['-ignore', %("#{@machine.config.unison.ignore}")] if @machine.config.unison.ignore
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
