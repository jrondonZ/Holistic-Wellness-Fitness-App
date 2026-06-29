module Api
  # Member-facing endpoint for the Sage wellness assistant. Authenticated,
  # per-user rate limited, and PHI-minimizing: the context handed to the engine
  # contains only derived wellness metrics for the *current* member, never direct
  # identifiers, and never another member's data.
  class AiController < ApplicationController
    # Legal gate doesn't apply to a JSON helper; auth still required (inherited).
    skip_before_action :enforce_legal_gate, raise: false

    RATE_LIMIT_KEY = ->(uid) { "sage_rate/#{uid}" }
    MAX_PER_MINUTE = 30
    MAX_HISTORY    = 10  # 5 user + 5 assistant turns — tight to stay inside small free tiers

    rescue_from StandardError do |e|
      Rails.logger.error("[AiCtrl] #{e.class}: #{e.message}\n#{e.backtrace.first(5).join("\n")}")
      render json: {
        reply:     "I'm here to support your wellness. Try asking about nutrition, movement, sleep, stress, or your chart.",
        timestamp: Time.current.iso8601
      }, status: :ok
    end

    def chat
      message = params[:message].to_s.strip
      return render json: { error: "Message required" },     status: :bad_request          if message.blank?
      return render json: { error: "Message too long" },     status: :unprocessable_entity if message.length > 1000
      return render json: { reply: "Let's take a breath between messages — try me again in a moment.",
                            timestamp: Time.current.iso8601 }, status: :ok                 unless within_rate_limit?

      context = build_context
      history = load_history
      history = (history + [ { role: "user", text: message } ]).last(MAX_HISTORY)

      # Adaptive provider chain: self-hosted local model → Groq (only if keyed) →
      # built-in grounded engine. Always returns a usable reply, never raises.
      result = Sage::Engine.new.reply(message, context: context, history: history)
      reply  = result.text

      history = (history + [ { role: "assistant", text: reply } ]).last(MAX_HISTORY)
      save_history(history)

      # Access trail: which engine answered (never the message contents — PHI).
      audit!(:ai_chat, metadata: { provider: result.provider })

      render json: { reply: reply, provider: result.provider, timestamp: Time.current.iso8601 }
    end

    private

    def within_rate_limit?
      key   = RATE_LIMIT_KEY.call(current_user.id)
      count = (Rails.cache.read(key) rescue 0).to_i
      return false if count >= MAX_PER_MINUTE
      Rails.cache.write(key, count + 1, expires_in: 1.minute) rescue nil
      true
    end

    # Hand Sage the member's live chart context so it can answer with their actual
    # trends instead of guessing. Only derived, member-facing metrics — no direct
    # identifiers (email, member ID, DOB, last name) — so the off-server footprint
    # stays minimal if a cloud model is ever configured.
    def build_context
      u   = current_user
      ctx = { first_name: u.first_name, local_time: Time.current.strftime("%a %-l:%M %p") }
      begin
        profile = u.health_profile
        ctx[:primary_goal] = profile&.primary_goal

        if (c = u.latest_checkin)
          ctx[:wellness_score] = c.wellness_score
          ctx[:mood_label]     = c.mood_label
          ctx[:energy_label]   = c.energy_label
          ctx[:stress_label]   = c.stress_label
          ctx[:sleep_hours]    = c.sleep_hours
          ctx[:resting_hr]     = c.resting_hr
          if c.blood_pressure
            ctx[:blood_pressure] = c.blood_pressure
            ctx[:bp_category]    = c.bp_category
          end
        end

        if profile && (bmi = profile.bmi)
          ctx[:bmi]          = bmi
          ctx[:bmi_category] = profile.bmi_category
        end

        ctx[:today_calories] = u.calories_for(Date.current)
        ctx[:calorie_target] = profile&.target_calories

        ctx[:week_minutes]  = u.workout_logs.this_week.sum(:duration_min)
        ctx[:week_sessions] = u.workout_logs.this_week.count
        ctx[:streak]        = checkin_streak(u)
      rescue StandardError => e
        Rails.logger.warn("[AiCtrl] context build skipped: #{e.message}")
      end
      ctx.compact
    end

    # Consecutive days (ending today or yesterday) with a check-in.
    def checkin_streak(user)
      dates = user.checkins.order(checkin_date: :desc).limit(60).pluck(:checkin_date).uniq
      return 0 if dates.empty?

      cursor = dates.first
      return 0 if cursor < Date.current - 1

      streak = 0
      dates.each do |d|
        break unless d == cursor
        streak += 1
        cursor -= 1
      end
      streak
    end

    # Session-scoped conversation memory, keyed by user id in Rails.cache so Sage
    # can recall earlier turns. Expires quickly so transcripts aren't retained.
    def history_key
      "sage_history/#{current_user.id}"
    end

    def load_history
      raw = Rails.cache.read(history_key) rescue nil
      raw.is_a?(Array) ? raw : []
    end

    def save_history(history)
      Rails.cache.write(history_key, history, expires_in: 2.hours) rescue nil
    end
  end
end
