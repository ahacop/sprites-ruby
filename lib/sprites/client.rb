# frozen_string_literal: true

require "faraday"
require "json"

module Sprites
  class Client
    def initialize(token: nil, base_url: nil)
      @token = token || Sprites.configuration.token
      @base_url = base_url || Sprites.configuration.base_url
    end

    def sprites
      Resources::Sprites.new(self)
    end

    def checkpoints
      Resources::Checkpoints.new(self)
    end

    def policies
      Resources::Policies.new(self)
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

    def parse_json(json) = JSON.parse(json, symbolize_names: true)

    def parse_ndjson(body) = body.each_line.map { parse_json(it) }

    def connection
      @connection ||= Faraday.new(url: @base_url) do |f|
        f.request :authorization, "Bearer", @token
      end
    end
  end
end
