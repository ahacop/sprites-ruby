# frozen_string_literal: true

require_relative "sprites/version"
require_relative "sprites/configuration"
require_relative "sprites/collection"
require_relative "sprites/sprite"
require_relative "sprites/resources/sprites"
require_relative "sprites/resources/checkpoints"
require_relative "sprites/resources/policies"
require_relative "sprites/resources/exec"
require_relative "sprites/client"

module Sprites
  class Error < StandardError; end

  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)
    end

    def reset_configuration
      @configuration = Configuration.new
    end
  end
end
