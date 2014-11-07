require 'browser'
module Sojourn

  def self.table_name_prefix
    'sojourn_'
  end

  class Visitor < ActiveRecord::Base

    has_many :visits, foreign_key: :sojourn_visitor_id
    has_many :events, through: :visits
    belongs_to :user

    before_create { self.uuid = SecureRandom.uuid }

    class << self

      def create_from_request!(request, user = nil, time = Time.now)
        create! ip_address: request.remote_ip,
                user_agent: request.user_agent,
                user: user,
                created_at: time
      end

    end

  end
end
