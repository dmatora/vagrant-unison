require "pathname"

require "vagrant-unison2/plugin"
require "vagrant-unison2/errors"

module VagrantPlugins
  module Unison
    # This returns the path to the source of this plugin.
    #
    # @return [Pathname]
    def self.source_root
      @source_root ||= Pathname.new(File.expand_path("../../", __FILE__))
    end
  end
end
