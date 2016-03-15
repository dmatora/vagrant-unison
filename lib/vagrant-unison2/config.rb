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
      # @return [String]
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

      def initialize(region_specific=false)
        @host_folder   = UNSET_VALUE
        @remote_folder = UNSET_VALUE
        @ignore        = UNSET_VALUE
        @repeat        = UNSET_VALUE
        @ssh_host      = UNSET_VALUE
        @ssh_port      = UNSET_VALUE
        @ssh_user      = UNSET_VALUE
      end

      #-------------------------------------------------------------------
      # Internal methods.
      #-------------------------------------------------------------------

      # def merge(other)
      #   super.tap do |result|
      #     # TODO - do something sensible; current last config wins
      #     result.local_folder = other.local_folder
      #     result.remote_folder = other.remote_folder
      #   end
      # end

      def finalize!
        # The access keys default to nil
        @host_folder  = nil         if @host_folder  == UNSET_VALUE
        @guest_folder = nil         if @guest_folder == UNSET_VALUE
        @ignore       = nil         if @ignore       == UNSET_VALUE
        @repeat       = 1           if @repeat       == UNSET_VALUE
        @ssh_host     = '127.0.0.1' if @ssh_host     == UNSET_VALUE
        @ssh_port     = 2222        if @ssh_port     == UNSET_VALUE
        @ssh_user     = 'vagrant'   if @ssh_user     == UNSET_VALUE

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
