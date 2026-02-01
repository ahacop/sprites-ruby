# frozen_string_literal: true

require "faraday"
require "json"

module Sprites
  # HTTP client for the Sprites API.
  #
  # @example
  #   client = Sprites::Client.new(token: "your-token")
  #   sprite = client.sprites.create(name: "my-sprite")
  #
  class Client
    # @return [String] the API token
    attr_reader :token

    # Create a new client.
    #
    # @param token [String, nil] API token (defaults to Sprites.configuration.token)
    # @param base_url [String, nil] API base URL (defaults to https://api.sprites.dev)
    def initialize(token: nil, base_url: nil)
      @token = token || Sprites.configuration.token
      @base_url = base_url || Sprites.configuration.base_url
    end

    # Access sprite operations.
    #
    # @return [Resources::Sprites]
    def sprites
      Resources::Sprites.new(self)
    end

    # Access checkpoint operations.
    #
    # @return [Resources::Checkpoints]
    def checkpoints
      Resources::Checkpoints.new(self)
    end

    # Access network policy operations.
    #
    # @return [Resources::Policies]
    def policies
      Resources::Policies.new(self)
    end

    # Access command execution operations.
    #
    # @return [Resources::Exec]
    def exec
      Resources::Exec.new(self)
    end

    # @return [String] WebSocket URL derived from base URL
    def websocket_url
      @base_url.sub(/^http(s?)/) { "ws#{$1}" }
    end

    # @return [Array<Array<String>>] authorization headers for WebSocket connections
    def auth_headers
      [["authorization", "Bearer #{@token}"]]
    end

    def get(path) = handle_response(connection.get(path))

    def post(path, body) = handle_response(connection.post(path, body.to_json, "Content-Type" => "application/json"))

    def put(path, body) = handle_response(connection.put(path, body.to_json, "Content-Type" => "application/json"))

    def delete(path) = handle_response(connection.delete(path))

    def post_stream(path, body, &block)
      response = connection.post(path, body.to_json, "Content-Type" => "application/json")

      raise_error(response.body) unless response.success?

      events = parse_ndjson(response.body)

      if (error_event = events.find { |e| e[:type] == "error" })
        raise Error, error_event[:error]
      end

      block_given? ? events.each(&block) : events
    end

    private

    def handle_response(response)
      case response.status
      in 204
        nil
      in 200..299
        parse_json(response.body)
      else
        raise_error(response.body)
      end
    end

    def raise_error(body)
      parsed = parse_json(body)
      message = parsed[:error] || parsed[:errors]&.join(", ") || "Unknown error"
      raise Error, message
    rescue JSON::ParserError
      raise Error, body.strip
    end

    def parse_json(json)
      return nil if json.to_s.empty?

      JSON.parse(json, symbolize_names: true)
    end

    def parse_ndjson(body) = body.each_line.map { parse_json(it) }

    def connection
      @connection ||= Faraday.new(url: @base_url) do |f|
        f.request :authorization, "Bearer", @token
      end
    end
  end
end
