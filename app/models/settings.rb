class Settings < ActiveRecord::Base
  include Singleton

  validate :notifications_email, format: { with: Devise.email_regexp }

  class << self
    delegate :inspect, to: :instance

    def method_missing(method, *args)
      instance.public_send(method, *args)
    end

    def instance
      @instance ||= first_or_create
    end
  end
end
