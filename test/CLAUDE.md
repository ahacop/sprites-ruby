# Test Guidelines

## Running Tests

```bash
rake test                                              # all tests
ruby -Ilib:test test/sprites/test_client.rb            # single file
ruby -Ilib:test test/sprites/test_client.rb -n test_sprites_list_empty  # single test
```

## Test Structure

```ruby
class TestCheckpoints < Minitest::Test
  def setup
    @client = Sprites::Client.new(token: ENV["SPRITES_TOKEN"])
  end

  private attr_reader :client

  def test_checkpoints_create
    VCR.use_cassette("checkpoints_create") do
      # test code
    end
  end
end
```

## Patterns

- Wrap HTTP calls in `VCR.use_cassette("cassette_name")` blocks
- Cassette name typically matches test name without `test_` prefix
- Clean up resources you create (delete sprites at end of test)
- Error cases: `assert_raises Sprites::Error`
- Type checking: `assert_kind_of Sprites::Sprite, sprite`
- Unit tests (like Collection) don't need VCR

## Assertions

Be specific with assertions so the return structure is clear from reading the test:

```ruby
# Bad - doesn't show what the response looks like
assert policy.key?(:egress)

# Good - documents the actual response structure
assert_equal "allow-all", policy[:egress][:policy]
```

## VCR Cassettes

- Stored in `test/cassettes/`
- Token filtered as `<SPRITES_TOKEN>`
- Set `SPRITES_TOKEN` in `.env.test.local` to record new cassettes
