require_relative 'campaign'
require_relative 'browser'
require_relative 'serializers/symbol'
require 'addressable/uri'
require 'referer-parser'

module Sojourn
  class Request < ActiveRecord::Base
    attr_accessor :user_agent

    serialize :method, Serializers::Symbol
    serialize :params

    belongs_to :campaign, foreign_key: :sojourn_campaign_id
    belongs_to :browser, foreign_key: :sojourn_browser_id
    has_many :events, foreign_key: :sojourn_request_id

    def self.from_request(request)
      new referer: request.referer.try(:truncate, 2048),
          host: request.host.try(:truncate, 2048),
          path: request.path.try(:truncate, 2048),
          controller: request.params[:controller],
          action: request.params[:action],
          params: request.filtered_parameters.with_indifferent_access.except(:controller, :action),
          method: request.request_method_symbol,
          ip_address: request.remote_ip,
          user_agent: request.user_agent
    end

    before_validation do
      self.campaign ||= Campaign.from_request(self)
      self.browser ||= Browser.from_request(self) if user_agent
    end

    def outside_referer?
      referer.present? && referer_host != host
    end

    def any_utm_data?
      tracked_param_keys.map { |p| downcased_params[p].present? }.any?
    end

    def tracked_params
      Hash[downcased_params.slice(*tracked_param_keys).delete_if { |_, v| v.blank? }.sort]
    end

    def browser_data
      return @browser_data if @browser_data
      b = browser.try(:send, :browser) || ::Browser.new(user_agent: user_agent)
      @browser_data = {
        name: b.name,
        version: b.version,
        platform: b.platform,
        bot: b.bot?,
        known: b.known?
      }
    end

    def referer_data
      return @referer_data if @referer_data
      p = RefererParser::Parser.new.parse(referer)
      @referer_data = {
        known: p[:known],
        host: referer_host,
        source: p[:source],
        medium: p[:medium],
        term: p[:term]
      }
    end

  private

    def referer_host
      @referer_host ||= Addressable::URI.parse(referer).host
    end

    def downcased_params
      params.each_with_object({}) { |(k, v), h| h[k.to_s.downcase] = v }
    end

    def tracked_param_keys
      Sojourn.config.campaign_params.map(&:to_s).map(&:downcase)
    end
  end
end
