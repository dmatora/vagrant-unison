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
            listener.stop if listener.paused? || listener.processing?
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
            command.batch = true
            command.terse = true
            command = command.to_s

            @env.ui.info "Running unison once"
            @env.ui.info "    #{command}"

            system(command)
          end
        end

        0
      end
    end

    class CommandPolling < Vagrant.plugin("2", :command)
      include UnisonSync
      attr_accessor :bg_thread

      def execute
        with_target_vms do |machine|
          @bg_thread = watch_vm_for_memory_leak(machine)

          execute_sync_command(machine) do |command|
            command.repeat = true
            command.terse = true
            command = command.to_s

            # @env.ui.info "Running #{command}"

            # Re-run on a crash.
            # On a sigint, wait 2 seconds before respawning command.
            # If INT comes in again while waiting, program exits.
            # If INT comes in after we've respanwned,
            # will bring us back to this trap handler.
            exit_on_next_sigint = false
            while true
              begin
                sleep 2 if exit_on_next_sigint
                exit_on_next_sigint = false
                system(command)
              rescue Interrupt
                if exit_on_next_sigint
                  Thread.kill(@bg_thread) if @bg_thread
                  exit 1
                end
                @env.ui.info '** Hit Ctrl + C again to kill. **'
                exit_on_next_sigint = true
              rescue Exception
                  @env.ui.info '** Sync crashed. Respawning. Hit Ctrl + C twice to kill. **'
              end
            end
          end
        end
        0
      end

      def watch_vm_for_memory_leak(machine)
        ssh_command = SshCommand.new(machine)
        unison_mem_cap_mb = 50
        Thread.new(ssh_command.command2, unison_mem_cap_mb) do |ssh_command_text, mem_cap_mb|
          while true
            sleep 2
            total_mem = `#{ssh_command_text} 'free -m | egrep "^Mem:" | awk "{print \\$2}"' 2>/dev/null`
            _unison_proc_returnval = `#{ssh_command_text} 'ps aux | grep "[u]nison -server" | awk "{print \\$2, \\$4}"' 2>/dev/null`
            if _unison_proc_returnval == ''
              puts "Unison not running in VM"
              next
            end
            pid, mem_pct_unison = _unison_proc_returnval.strip.split(' ')
            mem_unison = (total_mem.to_f * mem_pct_unison.to_f/100).round(1)
            puts "Unison running as #{pid} using #{mem_unison} mb"
            if mem_unison > mem_cap_mb
              puts "Unison using #{mem_unison} mb memory is over limit of #{mem_cap_mb}, restarting"
              `#{ssh_command_text} kill -HUP #{pid} 2>/dev/null`
            end
          end
        end
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

          command = "rm -rf #{guest_path}/* #{guest_path}/..?* #{guest_path}/.[!.]*"
          @env.ui.info "Running #{command} on guest VM (delete all files from directory including hidden ones)"
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
