# frozen_string_literal: true

require "async"
require "async/http/endpoint"
require "async/websocket/client"
require "io/console"
require "io/stream"
require "uri"

module Sprites
  module Resources
    class Exec
      STREAM_STDIN = 0
      STREAM_STDOUT = 1
      STREAM_STDERR = 2
      STREAM_EXIT = 3
      STREAM_STDIN_EOF = 4

      def initialize(client)
        @client = client
      end

      def create(sprite_name, command:)
        @client.post("/v1/sprites/#{sprite_name}/exec", { command: })
      end

      # Run a command and return the result (blocking)
      def run(sprite_name, command, **options)
        stdout = +""
        stderr = +""
        exit_code = nil

        connect(sprite_name, command: command, **options) do |_task, session|
          session.on_stdout { |data| stdout << data }
          session.on_stderr { |data| stderr << data }
          session.on_exit { |code| exit_code = code }
        end

        Result.new(stdout: stdout, stderr: stderr, exit_code: exit_code)
      end

      # Start an interactive terminal session wired to stdin/stdout
      #
      #   client.exec.interactive(sprite.name, ["bash"])
      #
      def interactive(sprite_name, command, input: $stdin, output: $stdout, **options)
        input.raw!
        stdin = IO::Stream::Buffered.wrap(input)

        connect(sprite_name, command: command, tty: true, **options) do |task, session|
          session.on_stdout do |data|
            output.write(data)
            output.flush
          end
          session.on_stderr do |data|
            output.write(data)
            output.flush
          end

          input_task = task.async do
            while (char = stdin.read(1))
              session.write(char)
            end
          rescue IOError
            # Connection closed
          end

          session.on_exit do |_code|
            input_task.stop
          end
        end
      ensure
        input.cooked!
      end

      # Connect to an interactive session
      #
      # Yields the Async task and session, allowing you to spawn concurrent tasks:
      #
      #   client.exec.connect(sprite.name, command: ["bash"], tty: true) do |task, session|
      #     session.on_stdout { |data| print data }
      #
      #     task.async do
      #       while (line = $stdin.gets)
      #         session.write(line)
      #       end
      #     end
      #   end
      #
      def connect(sprite_name, command: nil, tty: false, **options, &block)
        url = build_websocket_url(sprite_name, command, tty: tty, **options)
        endpoint = Async::HTTP::Endpoint.parse(url, alpn_protocols: ["http/1.1"])
        headers = Protocol::HTTP::Headers.new
        headers["authorization"] = "Bearer #{@client.token}"

        Async do |task|
          Async::WebSocket::Client.connect(endpoint, headers: headers) do |connection|
            session = Session.new(connection, tty: tty)

            # Run user's block and read loop concurrently
            task.async { block.call(task, session) }
            session.read_loop
          end
        end
      end

      private

      def build_websocket_url(sprite_name, command, tty:, **options)
        base = "#{@client.websocket_url}/v1/sprites/#{sprite_name}/exec"

        params = []
        Array(command).each { |arg| params << ["cmd", arg] }
        params << ["tty", "true"] if tty
        params << ["stdin", "true"] if options.fetch(:stdin, true)
        params << ["cols", options[:cols].to_s] if options[:cols]
        params << ["rows", options[:rows].to_s] if options[:rows]
        params << ["path", options[:path]] if options[:path]

        query = params.empty? ? "" : "?#{URI.encode_www_form(params)}"
        "#{base}#{query}"
      end

      Result = Data.define(:stdout, :stderr, :exit_code)

      class Session
        def initialize(connection, tty: false)
          @connection = connection
          @tty = tty
          @callbacks = { stdout: [], stderr: [], exit: [] }
          @exit_code = nil
        end

        attr_reader :exit_code

        def on_stdout(&block) = @callbacks[:stdout] << block
        def on_stderr(&block) = @callbacks[:stderr] << block
        def on_exit(&block) = @callbacks[:exit] << block

        def write(data)
          if @tty
            @connection.write(Protocol::WebSocket::BinaryMessage.new(data))
          else
            message = [STREAM_STDIN].pack("C") + data
            @connection.write(Protocol::WebSocket::BinaryMessage.new(message))
          end
          @connection.flush
        end

        def send_eof
          return if @tty

          message = [STREAM_STDIN_EOF].pack("C")
          @connection.write(Protocol::WebSocket::BinaryMessage.new(message))
          @connection.flush
        end

        def close
          @connection.close
        end

        def read_loop
          loop do
            message = @connection.read
            break unless message

            handle_message(message)
            break if @exit_code
          end
        end

        private

        def handle_message(message)
          data = message.respond_to?(:buffer) ? message.buffer : message.to_s

          if data.start_with?("{")
            handle_json_message(JSON.parse(data, symbolize_names: true))
          elsif @tty
            @callbacks[:stdout].each { |cb| cb.call(data) }
          else
            handle_binary_message(data)
          end
        end

        def handle_json_message(parsed)
          case parsed[:type]
          when "exit"
            @exit_code = parsed[:exit_code]
            @callbacks[:exit].each { |cb| cb.call(@exit_code) }
          end
        end

        def handle_binary_message(data)
          return if data.nil? || data.empty?

          stream_id = data.bytes[0]
          payload = data[1..]

          case stream_id
          when STREAM_STDOUT
            @callbacks[:stdout].each { |cb| cb.call(payload) }
          when STREAM_STDERR
            @callbacks[:stderr].each { |cb| cb.call(payload) }
          when STREAM_EXIT
            @exit_code = payload.unpack1("C")
            @callbacks[:exit].each { |cb| cb.call(@exit_code) }
          end
        end
      end
    end
  end
end
