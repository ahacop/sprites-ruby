# frozen_string_literal: true

require "async"
require "async/http/endpoint"
require "async/websocket/client"
require "io/console"
require "io/stream"
require "uri"

module Sprites
  module Resources
    # Command execution on sprites via HTTP and WebSocket.
    class Exec
      STREAM_STDIN = 0
      STREAM_STDOUT = 1
      STREAM_STDERR = 2
      STREAM_EXIT = 3
      STREAM_STDIN_EOF = 4

      def initialize(client)
        @client = client
      end

      # Execute a command via HTTP POST (non-streaming).
      #
      # @param sprite_name [String] sprite name
      # @param command [String] command to execute
      # @return [Hash] result with :exit_code and :output
      def create(sprite_name, command:)
        @client.post("/v1/sprites/#{sprite_name}/exec", { command: })
      end

      # List active exec sessions.
      #
      # @param sprite_name [String] sprite name
      # @return [Array<Hash>] sessions with :id, :command, :tty, :is_active, etc.
      def list(sprite_name)
        @client.get("/v1/sprites/#{sprite_name}/exec")
      end

      # Run a command via WebSocket and return the result (blocking).
      #
      # @param sprite_name [String] sprite name
      # @param command [Array<String>] command and arguments
      # @param options [Hash] WebSocket options (:cols, :rows, :path)
      # @return [Result] with stdout, stderr, and exit_code
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

      # Start an interactive terminal session wired to stdin/stdout.
      #
      # @param sprite_name [String] sprite name
      # @param command [Array<String>] command and arguments
      # @param input [IO] input stream (default: $stdin)
      # @param output [IO] output stream (default: $stdout)
      # @param options [Hash] WebSocket options (:cols, :rows)
      def interactive(sprite_name, command, input: $stdin, output: $stdout, **options)
        run_interactive(input: input, output: output) do |block|
          connect(sprite_name, command: command, tty: true, **options, &block)
        end
      end

      # Attach to an existing exec session.
      #
      # @param sprite_name [String] sprite name
      # @param session_id [Integer] session ID from #list
      # @param input [IO] input stream (default: $stdin)
      # @param output [IO] output stream (default: $stdout)
      def attach(sprite_name, session_id, input: $stdin, output: $stdout)
        run_interactive(input: input, output: output) do |block|
          connect(sprite_name, session_id: session_id, tty: true, &block)
        end
      end

      # Kill an exec session.
      #
      # @param sprite_name [String] sprite name
      # @param session_id [Integer] session ID from #list
      # @param signal [String, nil] signal to send (default: SIGTERM)
      # @param timeout [String, nil] timeout waiting for exit (default: 10s)
      # @yield [Hash] streaming NDJSON events (signal, exited, complete)
      # @return [Array<Hash>] all events if no block given
      def kill(sprite_name, session_id, signal: nil, timeout: nil, &block)
        body = {}
        body[:signal] = signal if signal
        body[:timeout] = timeout if timeout
        @client.post_stream("/v1/sprites/#{sprite_name}/exec/#{session_id}/kill", body, &block)
      end

      # Connect to a WebSocket exec session.
      #
      # Yields the Async task and session for concurrent I/O.
      #
      # @param sprite_name [String] sprite name
      # @param command [Array<String>, nil] command and arguments
      # @param tty [Boolean] enable TTY mode (default: false)
      # @param options [Hash] WebSocket options (:session_id, :cols, :rows, :path, :stdin)
      # @yield [Async::Task, Session] task and session for callbacks
      #
      # @example
      #   client.exec.connect(sprite.name, command: ["bash"], tty: true) do |task, session|
      #     session.on_stdout { |data| print data }
      #     task.async do
      #       while (line = $stdin.gets)
      #         session.write(line)
      #       end
      #     end
      #   end
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

      def run_interactive(input:, output:)
        input.raw!
        stdin = IO::Stream::Buffered.wrap(input)

        yield proc { |task, session|
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

          session.on_exit { |_code| input_task.stop }
        }
      ensure
        input.cooked!
      end

      def build_websocket_url(sprite_name, command, tty:, session_id: nil, **options)
        base = "#{@client.websocket_url}/v1/sprites/#{sprite_name}/exec"
        base = "#{base}/#{session_id}" if session_id

        params = []
        Array(command).each { |arg| params << ["cmd", arg] } unless session_id
        params << ["tty", "true"] if tty
        params << ["stdin", "true"] if options.fetch(:stdin, true)
        params << ["cols", options[:cols].to_s] if options[:cols]
        params << ["rows", options[:rows].to_s] if options[:rows]
        params << ["path", options[:path]] if options[:path]

        query = params.empty? ? "" : "?#{URI.encode_www_form(params)}"
        "#{base}#{query}"
      end

      # Result of a blocking command execution.
      # @!attribute [r] stdout
      #   @return [String] standard output
      # @!attribute [r] stderr
      #   @return [String] standard error
      # @!attribute [r] exit_code
      #   @return [Integer] process exit code
      Result = Data.define(:stdout, :stderr, :exit_code)

      # WebSocket session for interactive command execution.
      class Session
        def initialize(connection, tty: false)
          @connection = connection
          @tty = tty
          @callbacks = { stdout: [], stderr: [], exit: [] }
          @exit_code = nil
        end

        # @return [Integer, nil] exit code once process exits
        attr_reader :exit_code

        # Register a callback for stdout data.
        # @yield [String] stdout data
        def on_stdout(&block) = @callbacks[:stdout] << block

        # Register a callback for stderr data.
        # @yield [String] stderr data
        def on_stderr(&block) = @callbacks[:stderr] << block

        # Register a callback for process exit.
        # @yield [Integer] exit code
        def on_exit(&block) = @callbacks[:exit] << block

        # Write data to stdin.
        # @param data [String] data to write
        def write(data)
          if @tty
            @connection.write(Protocol::WebSocket::BinaryMessage.new(data))
          else
            message = [STREAM_STDIN].pack("C") + data
            @connection.write(Protocol::WebSocket::BinaryMessage.new(message))
          end
          @connection.flush
        end

        # Signal end of stdin (non-TTY mode only).
        def send_eof
          return if @tty

          message = [STREAM_STDIN_EOF].pack("C")
          @connection.write(Protocol::WebSocket::BinaryMessage.new(message))
          @connection.flush
        end

        # Close the WebSocket connection.
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
