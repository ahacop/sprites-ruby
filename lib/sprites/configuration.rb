# frozen_string_literal: true

module Sprites
  class Configuration
    attr_accessor :token, :base_url

    def initialize
      @base_url = "https://api.sprites.dev"
    end
  end
end
