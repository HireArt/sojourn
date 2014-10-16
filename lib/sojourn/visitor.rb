require 'browser'
module Sojourn

  def self.table_name_prefix
    'sojourn_'
  end

  class Visitor < ActiveRecord::Base

    has_many :visits, foreign_key: :sojourn_visitor_id
    belongs_to :user

    scope :unexpired, (lambda do
      eager_load(:visits).where('sojourn_visits.last_active_at > ?', 1.week.ago)
    end)

    before_create { self.uuid = SecureRandom.uuid }

    class << self

      def find_or_create_from_request(request, session, user = nil)
        return if bot?(request)
        find_from_session(session, user) || create_from_request!(request, session, user)
      end

      def find_from_session(session, user = nil)
        with_user where(uuid: session[:visitor_uuid]).unexpired.last, session, user
      end

      def create_from_request!(request, session, user = nil)
        visitor = create! ip_address: request.remote_ip, user_agent: request.user_agent, user: user
        session[:visitor_uuid] = visitor.uuid
        visitor
      end

    private

      def bot?(request)
        Browser.new(user_agent: request.user_agent).bot?
      end

      def with_user(visitor, session, user)
        return visitor if visitor.nil? || visitor.user_id == user.try(:id)
        visitor.update_attributes(user: user) and return visitor if user && visitor.user_id.nil?
        session[:visitor_uuid] = nil
      end

    end

  end
end
