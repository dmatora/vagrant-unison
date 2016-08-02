require "log4r"
require "vagrant"
require "thread"

require_relative 'unison_paths'
require_relative 'ssh_command'
require_relative 'shell_command'
require_relative 'unison_sync'

module VagrantPlugins
  module Unison
    class CommandOnce < Vagrant.plugin("2", :command)
      include UnisonSync

      def self.synopsis
        "sync the unison shared folder once"
      end

      def execute
        status = nil
        with_target_vms do |machine|
          execute_sync_command(machine) do |command|
            command.batch = true
            command.terse = true
            command = command.to_s

            @env.ui.info "Running unison once"
            @env.ui.info "    #{command}"

            status = system(command)
            @env.ui.info "**** unison exited. success: #{status} ****"
          end
        end
        if status
          return 0
        else
          return 1
        end
      end
    end

    class CommandPolling < Vagrant.plugin("2", :command)
      include UnisonSync
      attr_accessor :bg_thread

      def self.synopsis
        "sync the unison shared folder forever, by polling for changes"
      end

      def execute
        status = nil
        with_target_vms do |machine|
          @bg_thread = watch_vm_for_memory_leak(machine)
          execute_sync_command(machine) do |command|
            command.repeat = true
            command.terse = true
            command = command.to_s

            @env.ui.info "Running #{command}"

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
                status = system(command)
                @env.ui.info "**** unison exited. success: #{status} ****"
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
        if status
          return 0
        else
          return 1
        end
      end

      def watch_vm_for_memory_leak(machine)
        ssh_command = SshCommand.new(machine)
        Thread.new(ssh_command.ssh, machine.config.unison.mem_cap_mb) do |ssh_command_text, mem_cap_mb|
          while true
            sleep 15
            total_mem = `#{ssh_command_text} 'free -m | egrep "^Mem:" | awk "{print \\$2}"' 2>/dev/null`
            _unison_proc_returnval = (
              `#{ssh_command_text} 'ps aux | grep "[u]nison -server" | awk "{print \\$2, \\$4}"' 2>/dev/null`
            )
            if _unison_proc_returnval == ''
              puts "Unison not running in VM"
              next
            end
            pid, mem_pct_unison = _unison_proc_returnval.strip.split(' ')
            mem_unison = (total_mem.to_f * mem_pct_unison.to_f/100).round(1)
            # Debugging: uncomment to log every loop tick
            # puts "Unison running as #{pid} using #{mem_unison} mb"
            if mem_unison > mem_cap_mb
              puts "Unison using #{mem_unison}MB memory is over limit of #{mem_cap_mb}MB, restarting"
              `#{ssh_command_text} kill -HUP #{pid} 2>/dev/null`
            end
          end
        end
      end
    end

    class CommandCleanup < Vagrant.plugin("2", :command)
      def self.synopsis
        "remove all unison supporting state on local and remote system"
      end

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

      def self.synopsis
        "run unison in interactive mode, to resolve conflicts"
      end

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
