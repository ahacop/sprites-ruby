# Sprites

Ruby client for the [Sprites](https://sprites.dev) API - stateful sandbox environments.

## Installation

Add this line to your application's Gemfile:

```ruby
gem "sprites-ruby"
```

## Getting Started

Create a client

```ruby
client = Sprites::Client.new(token: ENV["SPRITES_TOKEN"])
```

Or configure globally

```ruby
Sprites.configure do |config|
  config.token = ENV["SPRITES_TOKEN"]
end

client = Sprites::Client.new
```

## Sprites

Create a sprite

```ruby
sprite = client.sprites.create(name: "my-sprite")
```

Create and wait until ready

```ruby
sprite = client.sprites.create(name: "my-sprite", wait: true)
```

List sprites

```ruby
collection = client.sprites.list
collection.sprites.each { |s| puts s.name }
```

Get a sprite

```ruby
sprite = client.sprites.retrieve("my-sprite")
sprite.status # => "warm"
```

Update a sprite

```ruby
sprite = client.sprites.update("my-sprite", url_settings: { auth: "public" })
```

Delete a sprite

```ruby
client.sprites.delete("my-sprite")
```

## Command Execution

Run a command (HTTP, simple)

```ruby
result = client.exec.create("my-sprite", command: "echo hello")
result[:output]    # => "hello\n"
result[:exit_code] # => 0
```

Run a command (WebSocket, streaming)

```ruby
result = client.exec.run("my-sprite", ["ls", "-la"])
result.stdout
result.stderr
result.exit_code
```

Interactive terminal session

```ruby
client.exec.interactive("my-sprite", ["bash"])
```

With custom I/O

```ruby
client.exec.interactive("my-sprite", ["bash"], input: $stdin, output: $stdout)
```

## Sessions

List active sessions

```ruby
sessions = client.exec.list("my-sprite")
sessions.each { |s| puts "#{s[:id]}: #{s[:command]}" }
```

Attach to a session

```ruby
client.exec.attach("my-sprite", session_id)
```

Kill a session

```ruby
client.exec.kill("my-sprite", session_id)
```

With a specific signal

```ruby
client.exec.kill("my-sprite", session_id, signal: "SIGKILL")
```

## Checkpoints

Create a checkpoint

```ruby
client.checkpoints.create("my-sprite", comment: "before deploy")
```

List checkpoints

```ruby
checkpoints = client.checkpoints.list("my-sprite")
```

Restore a checkpoint

```ruby
client.checkpoints.restore("my-sprite", checkpoint_id)
```

## Network Policies

Get current policy

```ruby
policy = client.policies.retrieve("my-sprite")
policy[:egress][:policy] # => "allow-all"
```

Update policy

```ruby
client.policies.update("my-sprite", egress: { policy: "block-all" })
```

## Low-Level WebSocket API

For advanced use cases, use `connect` directly

```ruby
client.exec.connect("my-sprite", command: ["bash"], tty: true) do |task, session|
  session.on_stdout { |data| print data }
  session.on_stderr { |data| $stderr.print data }
  session.on_exit { |code| puts "Exit: #{code}" }

  task.async do
    while (line = $stdin.gets)
      session.write(line)
    end
  end
end
```

## Development

```sh
bundle install
rake test
```

### Releasing

```sh
rake release            # build, tag, push gem to RubyGems
just release          # create GitHub release with CHANGELOG notes
```

## License

MIT
