# frozen_string_literal: true

module Sprites
  # Paginated collection of sprites.
  class Collection
    # @return [Array<Sprite>] sprites in this page
    attr_reader :sprites

    # @return [String, nil] token for fetching the next page
    attr_reader :next_continuation_token

    def initialize(sprites:, has_more:, next_continuation_token:)
      @sprites = sprites
      @has_more = has_more
      @next_continuation_token = next_continuation_token
    end

    # Check if more pages are available.
    #
    # @return [Boolean]
    def has_more?
      @has_more && !@next_continuation_token.nil?
    end
  end
end
