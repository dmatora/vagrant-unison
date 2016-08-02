module VagrantPlugins
  module Unison
    class ShellCommand
      def initialize(machine, unison_paths, ssh_command)
        @machine = machine
        @unison_paths = unison_paths
        @ssh_command = ssh_command
      end

      attr_accessor :batch, :repeat, :terse
      attr_accessor :force_remote, :force_local
      attr_accessor :prefer_remote, :prefer_local

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
          local_root_arg,
          remote_root_arg,
          batch_arg,
          terse_arg,
          repeat_arg,
          ignore_arg,
          perms_arg,
          force_arg,
          prefer_arg,
          ssh_args,
        ].flatten.compact
        _args
      end

      def local_root_arg
        @unison_paths.host
      end

      def remote_root_arg
        @ssh_command.uri(@unison_paths)
      end

      def ssh_args
        ['-sshargs', %("#{@ssh_command.ssh_args}")]
      end

      def batch_arg
        '-batch' if batch
      end

      def ignore_arg
        patterns = []
        if @machine.config.unison.ignore.is_a? ::Array
          patterns += @machine.config.unison.ignore
        elsif @machine.config.unison.ignore
          patterns << @machine.config.unison.ignore
        end

        patterns.map do |pattern|
          ['-ignore', %("#{pattern}")]
        end
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

      # from the docs:
      #
      # Including the preference  -force root causes Unison to resolve all
      # differences (even non-conflicting changes) in favor of root. This
      # effectively changes Unison from a synchronizer into a mirroring
      # utility. You can also specify -force newer (or  -force older) to force
      # Unison to choose the file with the later (earlier) modtime. In this
      # case, the  -times preference must also be enabled. This preference is
      # overridden by the forcepartial preference. This preference should be
      # used only if you are sure you know what you are doing!
      #
      # soo. I'm not sure if I know what I'm doing. Need to make sure that this
      # doesn't end up deleting .git or some other ignored but critical
      # directory.
      def force_arg
        return ['-force', local_root_arg] if force_local
        return ['-force', remote_root_arg] if force_remote
      end

      # from the docs, via Daniel Low (thx daniel):
      #
      # Including the preference -prefer root causes Unison always to resolve
      # conflicts in favor of root, rather than asking for guidance from the
      # user.
      #
      # This is much safer than -force
      def prefer_arg
        return ['-prefer', local_root_arg] if prefer_local
        return ['-prefer', remote_root_arg] if prefer_remote
      end
    end
  end
end
