# frozen_string_literal: true

module Sprites
  class Collection
    attr_reader :sprites, :next_continuation_token

    def initialize(sprites:, has_more:, next_continuation_token:)
      @sprites = sprites
      @has_more = has_more
      @next_continuation_token = next_continuation_token
    end

    def has_more?
      @has_more && !@next_continuation_token.nil?
    end
  end
end
