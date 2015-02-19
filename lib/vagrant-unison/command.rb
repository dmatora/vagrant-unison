require "log4r"
require "vagrant"
require "thread"
require 'listen'

module VagrantPlugins
  module Unison
    class Command < Vagrant.plugin("2", :command)
      
      def execute
        
        with_target_vms do |machine|
          hostpath, guestpath = init_paths machine

          trigger_unison_sync machine

          @env.ui.info "Watching #{hostpath} for changes..."

          listener = Listen.to(hostpath) do |modified, added, removed|
            @env.ui.info "Detected modifications to #{modified.inspect}" unless modified.empty?
            @env.ui.info "Detected new files #{added.inspect}" unless added.empty?
            @env.ui.info "Detected deleted files #{removed.inspect}" unless removed.empty?
            
            trigger_unison_sync machine
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

        0  #all is well
      end

      def init_paths(machine)
          hostpath  = File.expand_path(machine.config.sync.host_folder, @env.root_path)
          guestpath = machine.config.sync.guest_folder

          # Make sure there is a trailing slash on the host path to
          # avoid creating an additional directory with rsync
          hostpath = "#{hostpath}/" if hostpath !~ /\/$/

          [hostpath, guestpath]
      end

      def trigger_unison_sync(machine)
        hostpath, guestpath = init_paths machine

        @env.ui.info "Unisoning changes from {host}::#{hostpath} --> {guest VM}::#{guestpath}"

        ssh_info = machine.ssh_info

        # Create the guest path
        machine.communicate.sudo("mkdir -p '#{guestpath}'")
        machine.communicate.sudo("chown #{ssh_info[:username]} '#{guestpath}'")

        proxy_command = ""
        if ssh_info[:proxy_command]
          proxy_command = "-o ProxyCommand='#{ssh_info[:proxy_command]}' "
        end

        rsh = [
          "-p #{ssh_info[:port]} " +
          proxy_command +
          "-o StrictHostKeyChecking=no " +
          "-o UserKnownHostsFile=/dev/null",
          ssh_info[:private_key_path].map { |p| "-i #{p}" },
        ].flatten.join(" ")

        # Unison over to the guest path using the SSH info
        ignore = machine.config.sync.ignore ? '-ignore "'+machine.config.sync.ignore+'" ' : '';
        command = [
          "unison", "-batch",
          "-sshargs", rsh,
          hostpath,
          "ssh://#{ssh_info[:username]}@#{ssh_info[:host]}/#{guestpath}"
         ]
        if machine.config.sync.ignore
          command []= ignore
        end

        r = Vagrant::Util::Subprocess.execute(*command)
        case r.exit_code
        when 0
          @env.ui.info "Unison completed succesfully"
        when 1
          @env.ui.info "Unison completed - all file transfers were successful; some files were skipped"
        when 2
          @env.ui.info "Unison completed - non-fatal failures during file transfer"
        else
          raise Vagrant::Errors::UnisonError,
            :command => command.inspect,
            :guestpath => guestpath,
            :hostpath => hostpath,
            :stderr => r.stderr
        end
      end
     
    end
    class CommandRepeat < Vagrant.plugin("2", :command)

      def execute

        with_target_vms do |machine|
          hostpath, guestpath = init_paths machine

          trigger_unison_sync machine

        end

        0  #all is well
      end

      def init_paths(machine)
          hostpath  = File.expand_path(machine.config.sync.host_folder, @env.root_path)
          guestpath = machine.config.sync.guest_folder

          # Make sure there is a trailing slash on the host path to
          # avoid creating an additional directory with rsync
          hostpath = "#{hostpath}/" if hostpath !~ /\/$/

          [hostpath, guestpath]
      end

      def trigger_unison_sync(machine)
        hostpath, guestpath = init_paths machine

        @env.ui.info "Unisoning changes from {host}::#{hostpath} --> {guest VM}::#{guestpath}"

        ssh_info = machine.ssh_info

        # Create the guest path
        machine.communicate.sudo("mkdir -p '#{guestpath}'")
        machine.communicate.sudo("chown #{ssh_info[:username]} '#{guestpath}'")

        proxy_command = ""
        if ssh_info[:proxy_command]
          proxy_command = "-o ProxyCommand='#{ssh_info[:proxy_command]}' "
        end

        rsh = [
          "-p #{ssh_info[:port]} " +
          proxy_command +
          "-o StrictHostKeyChecking=no " +
          "-o UserKnownHostsFile=/dev/null",
          ssh_info[:private_key_path].map { |p| "-i #{p}" },
        ].flatten.join(" ")

        # Unison over to the guest path using the SSH info
        ignore = machine.config.sync.ignore ? ' -ignore "'+machine.config.sync.ignore+'"' : '';
        command = 'unison -terse -repeat 1 -sshargs "'+rsh+'" '+hostpath+' '+"ssh://#{ssh_info[:username]}@#{ssh_info[:host]}/#{guestpath}"+ignore
        @env.ui.info "Running #{command}"

        system(command)
      end

    end
    class CommandCleanup < Vagrant.plugin("2", :command)

      def execute

        with_target_vms do |machine|
          hostpath, guestpath = init_paths machine

          trigger_unison_sync machine

        end

        0  #all is well
      end

      def init_paths(machine)
          hostpath  = File.expand_path(machine.config.sync.host_folder, @env.root_path)
          guestpath = machine.config.sync.guest_folder

          # Make sure there is a trailing slash on the host path to
          # avoid creating an additional directory with rsync
          hostpath = "#{hostpath}/" if hostpath !~ /\/$/

          [hostpath, guestpath]
      end

      def trigger_unison_sync(machine)
        hostpath, guestpath = init_paths machine

        # Unison over to the guest path using the SSH info
        command = "rm -rf ~/Library/'Application Support'/Unison/* ; rm -rf #{guestpath}/*"
        @env.ui.info "Running #{command}"

        system(command)
      end

    end
    class CommandInteract < Vagrant.plugin("2", :command)

      def execute

        with_target_vms do |machine|
          hostpath, guestpath = init_paths machine

          trigger_unison_sync machine

        end

        0  #all is well
      end

      def init_paths(machine)
          hostpath  = File.expand_path(machine.config.sync.host_folder, @env.root_path)
          guestpath = machine.config.sync.guest_folder

          # Make sure there is a trailing slash on the host path to
          # avoid creating an additional directory with rsync
          hostpath = "#{hostpath}/" if hostpath !~ /\/$/

          [hostpath, guestpath]
      end

      def trigger_unison_sync(machine)
        hostpath, guestpath = init_paths machine

        @env.ui.info "Unisoning changes from {host}::#{hostpath} --> {guest VM}::#{guestpath}"

        ssh_info = machine.ssh_info

        # Create the guest path
        machine.communicate.sudo("mkdir -p '#{guestpath}'")
        machine.communicate.sudo("chown #{ssh_info[:username]} '#{guestpath}'")

        proxy_command = ""
        if ssh_info[:proxy_command]
          proxy_command = "-o ProxyCommand='#{ssh_info[:proxy_command]}' "
        end

        rsh = [
          "-p #{ssh_info[:port]} " +
          proxy_command +
          "-o StrictHostKeyChecking=no " +
          "-o UserKnownHostsFile=/dev/null",
          ssh_info[:private_key_path].map { |p| "-i #{p}" },
        ].flatten.join(" ")

        # Unison over to the guest path using the SSH info
        ignore = machine.config.sync.ignore ? ' -ignore "'+machine.config.sync.ignore+'"' : '';
        command = 'unison -terse -sshargs "'+rsh+'" hosts '+"ssh://#{ssh_info[:username]}@#{ssh_info[:host]}/#{guestpath}"+ignore
        @env.ui.info "Running #{command}"

        system(command)
      end

    end
  end
end
