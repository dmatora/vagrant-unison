require "vagrant"

module VagrantPlugins
  module Unison
    class Config < Vagrant.plugin("2", :config)
      # Host Folder to Sync
      #
      # @return [String]
      attr_accessor :unison_host_folder

      # Guest Folder to Sync.
      #
      # @return [String]
      attr_accessor :unison_guest_folder

      # Pattern of files to ignore.
      #
      # @return [String]
      attr_accessor :unison_ignore

      # Repeat speed.
      #
      # @return [String]
      attr_accessor :unison_repeat

      def initialize(region_specific=false)
        @unison_host_folder = UNSET_VALUE
        @remote_folder      = UNSET_VALUE
        @unison_ignore      = UNSET_VALUE
        @unison_repeat      = UNSET_VALUE
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
        @unison_host_folder  = nil if @unison_host_folder  == UNSET_VALUE
        @unison_guest_folder = nil if @unison_guest_folder == UNSET_VALUE
        @unison_ignore       = nil if @unison_ignore       == UNSET_VALUE
        @unison_repeat       = 1   if @unison_repeat       == UNSET_VALUE

        # Mark that we finalized
        @__finalized = true
      end

      def validate(machine)
        errors = []

        if !(@unison_host_folder.nil? && @unison_guest_folder.nil?)
          errors << I18n.t("vagrant_unison.config.unison_host_folder_required") if @unison_host_folder.nil?
          errors << I18n.t("vagrant_unison.config.unison_guest_folder_required") if @unison_guest_folder.nil?
        end

        { "Unison" => errors }
      end
    end
  end
end
