require "vagrant"

module Vagrant
  module Errors
    class UnisonError < VagrantError
      error_key(:unison_error, "vagrant_unison.errors")
    end
  end
end
