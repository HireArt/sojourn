require_relative 'visitor'
require_relative 'visit'
module Sojourn
  class VisitTracker

    def initialize(request, session, current_user = nil, now = Time.now)
      self.request, self.session, self.current_user, @now = request, session, current_user, now
    end

    def current_visit
      @current_visit ||= Visit.find_by_uuid(session[:sojourn_visit_uuid])
    end

    def current_visitor
      @current_visitor ||= Visitor.find_by_uuid(session[:sojourn_visitor_uuid])
    end

    def track!(time = Time.now)
      return if request.bot?
      track_visitor!(time) if should_track_visitor?
      if should_track_visit?
        track_visit!(time)
      elsif user_added?
        track_user_change!
      end
      mark_active!(time)
    end

    def track_visitor!(time = Time.now)
      @current_visitor = Visitor.create!(created_at: time)
      session[:sojourn_visitor_uuid] = @current_visitor.uuid
      session[:sojourn_visit_uuid] = nil
      session[:sojourn_last_active_at] = nil
    end

    def track_visit!(time = Time.now)
      @current_visit = current_visitor.visits.create!(request: request, user: current_user, created_at: time)
      session[:sojourn_visit_uuid] = @current_visit.uuid
      session[:sojourn_current_user_id] = current_user.try(:id)
    end

    def track_user_change!
      current_visit.update_attributes(user_id: current_user.try(:id))
      session[:sojourn_current_user_id] = current_user.try(:id)
    end

    def mark_active!(time = Time.now)
      session[:sojourn_last_active_at] = time
    end

  private

    attr_accessor :request, :session, :current_user

    # Visitor Tracking Policy

    def should_track_visitor?
      unknown_visitor? || expired_visitor?
    end

    def unknown_visitor?
      session[:sojourn_visitor_uuid].blank?
    end

    def expired_visitor?
      return unless Sojourn.config.visitor_expires_after
      session[:sojourn_last_active_at] < @now - Sojourn.config.visitor_expires_after
    end

    # Visit Tracking Policy

    def should_track_visit?
      unknown_visit? || expired_visit? || logged_out? || new_visit_required?
    end

    def unknown_visit?
      session[:sojourn_visit_uuid].blank?
    end

    def expired_visit?
      return unless Sojourn.config.visit_expires_after
      session[:sojourn_last_active_at] < @now - Sojourn.config.visit_expires_after
    end

    def logged_out?
      user_changed? && !user_added?
    end

    def user_changed?
      current_user.try(:id) != session[:sojourn_current_user_id]
    end

    def user_added?
      current_user && session[:sojourn_current_user_id].blank?
    end

    def new_visit_required?
      request.outside_referer? || request.any_utm_data?
    end
  end
end
