require "log4r"
require "vagrant"
require "thread"
require 'listen'

require_relative 'unison_paths'
require_relative 'ssh_command'
require_relative 'shell_command'
require_relative 'unison_sync'

module VagrantPlugins
  module Unison
    class Command < Vagrant.plugin("2", :command)
      include UnisonSync

      def execute
        with_target_vms do |machine|
          paths = UnisonPaths.new(@env, machine)
          host_path = paths.host

          sync(machine, paths)

          @env.ui.info "Watching #{host_path} for changes..."

          listener = Listen.to(host_path) do |modified, added, removed|
            @env.ui.info "Detected modifications to #{modified.inspect}" unless modified.empty?
            @env.ui.info "Detected new files #{added.inspect}" unless added.empty?
            @env.ui.info "Detected deleted files #{removed.inspect}" unless removed.empty?

            sync(machine, paths)
          end

          queue = Queue.new

          callback = lambda do
            # This needs to execute in another thread because Thread
            # synchronization can't happen in a trap context.
            Thread.new { queue << true }
          end

          # Run the listener in a busy block so that we can cleanly
          # exit once we receive an interrupt.
          Vagrant::Util::Busy.busy(callback) do
            listener.start
            queue.pop
            listener.stop if listener.listen?
          end
        end

        0
      end

      def sync(machine, paths)
        execute_sync_command(machine) do |command|
          command.batch = true

          @env.ui.info "Running #{command.to_s}"

          r = Vagrant::Util::Subprocess.execute(*command.to_a)

          case r.exit_code
          when 0
            @env.ui.info "Unison completed succesfully"
          when 1
            @env.ui.info "Unison completed - all file transfers were successful; some files were skipped"
          when 2
            @env.ui.info "Unison completed - non-fatal failures during file transfer: #{r.stderr}"
          else
            raise Vagrant::Errors::UnisonError,
              :command => command.to_s,
              :guestpath => paths.guest,
              :hostpath => paths.host,
              :stderr => r.stderr
          end
        end
      end
    end

    class CommandOnce < Vagrant.plugin("2", :command)
      include UnisonSync

      def execute
        with_target_vms do |machine|
          execute_sync_command(machine) do |command|
            command.repeat = false
            command.terse = true
            command.batch = true
            command = command.to_s

            @env.ui.info "Running unison once"
            @env.ui.info "    #{command}"

            system(command)
          end
        end

        0
      end
    end

    class CommandRepeat < Vagrant.plugin("2", :command)
      include UnisonSync

      def execute
        with_target_vms do |machine|
          execute_sync_command(machine) do |command|
            command.repeat = true
            command.terse = true
            command = command.to_s

            @env.ui.info "Running #{command}"

            system(command)
          end
        end

        0
      end
    end

    class CommandCleanup < Vagrant.plugin("2", :command)
      include UnisonSync

      def execute
        with_target_vms do |machine|
          guest_path = UnisonPaths.new(@env, machine).guest

          command = "rm -rf ~/Library/'Application Support'/Unison/*"
          @env.ui.info "Running #{command} on host"
          system(command)

          command = "rm -rf #{guest_path}"
          @env.ui.info "Running #{command} on guest VM"
          machine.communicate.sudo(command)

          command = "rm -rf ~/.unison"
          @env.ui.info "Running #{command} on guest VM"
          machine.communicate.execute(command)
        end

        0
      end
    end

    class CommandInteract < Vagrant.plugin("2", :command)
      include UnisonSync

      def execute
        with_target_vms do |machine|
          execute_sync_command(machine) do |command|
            command.terse = true
            command = command.to_s

            @env.ui.info "Running #{command}"

            system(command)
          end
        end

        0
      end
    end
  end
end
