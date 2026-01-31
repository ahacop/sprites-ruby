# frozen_string_literal: true

module Sprites
  class Sprite
    def self.to_proc = ->(attrs) { new(**attrs) }

    attr_reader :id, :name, :status, :version, :url, :created_at, :updated_at,
                :organization, :url_settings, :environment_version

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
