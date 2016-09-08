require "optparse"

module VagrantPlugins
  module Unison
    # mixin providing common functionality for our vagrant commands
    module UnisonSync
      def execute_sync_command(machine)
        parse_options!

        unison_paths = UnisonPaths.new(@env, machine)
        guest_path = unison_paths.guest
        host_path = unison_paths.host

        @env.ui.info "Unisoning changes from {host}::#{host_path} --> {guest VM}::#{guest_path}"

        # Create the guest path
        machine.communicate.sudo("mkdir -p '#{guest_path}'")
        machine.communicate.sudo("chown #{machine.config.unison.ssh_user} '#{guest_path}'")

        ssh_command = SshCommand.new(machine)
        shell_command = ShellCommand.new(machine, unison_paths, ssh_command)

        shell_command.prefer_local = options[:prefer_local]
        shell_command.prefer_remote = options[:prefer_remote]
        shell_command.force_local = options[:force_local]
        shell_command.force_remote = options[:force_remote]

        yield shell_command
      end

      def parse_options!
        # parse_options(option_parser) is provided by vagrant, but
        # documentation is scarse. Best way to view the docs (imo) is to put
        # a binding.pry in here and then type `? parse_options`
        @parsed_argv ||= parse_options(options_parser)

        if options[:verbose]
          @env.ui.info "Options: #{options}"
        end

        # According to the docs:
        # > If parse_options returns `nil`, then you should assume that
        # > help was printed and parsing failed.
        if @parsed_argv == nil
          exit 1
        end
      end

      def options
        @options ||= {
          :prefer_local => false,
          :prefer_remote => false,
          :force_local => false,
          :force_remote => false,
          :verbose => false,
        }
      end

      def options_parser
        @option_parser ||= OptionParser.new do |o|
          o.banner = "Usage: vagrant #{ARGV[0]} [options]"

          o.on('--push', 'prefer changes on the local machine.') do |flag|
            options[:prefer_local] = flag
            check_conflicting_options!
          end

          o.on('--pull', 'prefer changes on the remote machine.') do |flag|
            options[:prefer_remote] = flag
            check_conflicting_options!
          end

          o.on('--force-push', 'force-push changes to the remote machine. Dangerous!') do |flag|
            options[:force_local] = flag
            check_conflicting_options!
          end

          o.on('--force-pull', 'force-pull changes from the remote machine. Super dangerous!') do |flag|
            options[:force_remote] = flag
            check_conflicting_options!
          end

          o.on('--verbose', 'Print additional debug information') do |flag|
            options[:verbose] = flag
          end
        end
      end

      def check_conflicting_options!
        enabled = [:prefer_local, :prefer_remote, :force_local, :force_remote].select do |opt|
          options[opt]
        end
        raise ArgumentError.new("Conflicting options: #{enabled.inspect}") if enabled.length > 1
      end
    end
  end
end
