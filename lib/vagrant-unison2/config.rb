require "vagrant"

module VagrantPlugins
  module Unison
    class Config < Vagrant.plugin("2", :config)
      # Host Folder to Sync
      #
      # @return [String]
      attr_accessor :host_folder

      # Guest Folder to Sync.
      #
      # @return [String]
      attr_accessor :guest_folder

      # Pattern of files to ignore.
      #
      # @return [String, Array<String>]
      attr_accessor :ignore

      # Repeat speed.
      #
      # @return [String]
      attr_accessor :repeat

      # SSH host.
      #
      # @return [String]
      attr_accessor :ssh_host

      # SSH port.
      #
      # @return [String]
      attr_accessor :ssh_port

      # SSH user.
      #
      # @return [String]
      attr_accessor :ssh_user

      # Memory usage cap in MB
      # Restart Unison in the VM when it's consuming more than this
      # amount of memory (in MB)
      # @return [int]
      attr_accessor :mem_cap_mb

      # perms arg value
      #
      # @return [int]
      attr_accessor :perms

      # Airlab-specific config option to leave off the Vagrant identity file, so
      # SSH will just use ssh-agent
      #
      # @return [Boolean]
      attr_accessor :ssh_use_agent

      def initialize(region_specific = false)
        @host_folder   = UNSET_VALUE
        @guest_folder  = UNSET_VALUE
        @ignore        = UNSET_VALUE
        @repeat        = UNSET_VALUE
        @ssh_host      = UNSET_VALUE
        @ssh_port      = UNSET_VALUE
        @ssh_user      = UNSET_VALUE
        @ssh_use_agent = UNSET_VALUE
        @mem_cap_mb    = UNSET_VALUE
        @perms         = UNSET_VALUE
      end

      def finalize!
        # The access keys default to nil
        @host_folder  = nil         if @host_folder  == UNSET_VALUE
        @guest_folder = nil         if @guest_folder == UNSET_VALUE
        @ignore       = nil         if @ignore       == UNSET_VALUE
        @repeat       = 1           if @repeat       == UNSET_VALUE
        @ssh_host     = '127.0.0.1' if @ssh_host     == UNSET_VALUE
        @ssh_port     = 2222        if @ssh_port     == UNSET_VALUE
        @ssh_user     = 'vagrant'   if @ssh_user     == UNSET_VALUE
        @mem_cap_mb   = 200         if @mem_cap_mb   == UNSET_VALUE
        @perms        = nil         if @perms        == UNSET_VALUE
        @ssh_use_agent = false      if @ssh_use_agent == UNSET_VALUE

        # Mark that we finalized
        @__finalized = true
      end

      def validate(machine)
        errors = []

        if !(@host_folder.nil? && @guest_folder.nil?)
          errors << I18n.t("vagrant_unison.config.unison_host_folder_required") if @host_folder.nil?
          errors << I18n.t("vagrant_unison.config.unison_guest_folder_required") if @guest_folder.nil?
        end

        { "Unison" => errors }
      end
    end
  end
end
