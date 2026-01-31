# frozen_string_literal: true

require "test_helper"

class TestCollection < Minitest::Test
  def test_sprites_accessor
    collection = Sprites::Collection.new(sprites: [{ id: "1" }], has_more: false, next_continuation_token: nil)

    assert_equal [{ id: "1" }], collection.sprites
  end

  def test_has_more_true
    collection = Sprites::Collection.new(sprites: [{ id: "1" }], has_more: true, next_continuation_token: "abc123")

    assert collection.has_more?
  end

  def test_has_more_false
    collection = Sprites::Collection.new(sprites: [], has_more: false, next_continuation_token: nil)

    refute collection.has_more?
  end

  def test_has_more_bug_workaround
    # sprites.dev returns has_more: true even when there are no more results
    # we detect this by checking if next_continuation_token is nil
    collection = Sprites::Collection.new(sprites: [{ id: "1" }], has_more: true, next_continuation_token: nil)

    refute collection.has_more?
  end

  def test_next_continuation_token
    collection = Sprites::Collection.new(sprites: [], has_more: true, next_continuation_token: "abc123")

    assert_equal "abc123", collection.next_continuation_token
  end
end
