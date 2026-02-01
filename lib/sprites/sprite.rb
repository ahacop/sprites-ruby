# frozen_string_literal: true

module Sprites
  # A sprite instance.
  class Sprite
    # @api private
    def self.to_proc = ->(attrs) { new(**attrs) }

    # @return [String] unique sprite ID
    attr_reader :id

    # @return [String] sprite name
    attr_reader :name

    # @return [String] status ("cold", "warm")
    attr_reader :status

    # @return [String, nil] sprite version
    attr_reader :version

    # @return [String] public URL for the sprite
    attr_reader :url

    # @return [String] creation timestamp
    attr_reader :created_at

    # @return [String] last update timestamp
    attr_reader :updated_at

    # @return [String] organization slug
    attr_reader :organization

    # @return [Hash] URL authentication settings
    attr_reader :url_settings

    # @return [String, nil] environment version
    attr_reader :environment_version

    def initialize(id:, name:, status:, version:, url:, created_at:, updated_at:,
                   organization:, url_settings:, environment_version:)
      @id = id
      @name = name
      @status = status
      @version = version
      @url = url
      @created_at = created_at
      @updated_at = updated_at
      @organization = organization
      @url_settings = url_settings
      @environment_version = environment_version
    end
  end
end
