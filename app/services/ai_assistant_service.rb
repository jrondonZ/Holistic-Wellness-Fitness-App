# app/services/ai_assistant_service.rb
require "net/http"
require "json"

# OpenAI-compatible chat client for Sage. Defaults to Groq's free-tier Llama, but
# the endpoint/model/key are injectable so the exact same prompt + context +
# history handling can drive a local, key-less server (Ollama, llama.cpp, vLLM, LM
# Studio …) that keeps member data on your own infrastructure. When no api_key is
# given and the endpoint isn't Groq, requests are sent without an Authorization
# header — which is how local servers expect them.
#
# PRIVACY: only minimal, member-facing *derived* wellness metrics are ever placed
# in the prompt (first name, goal, scores, counts) — never direct identifiers like
# full name, email, member ID, or date of birth. With the default grounded engine
# nothing is sent off-server at all; this client only runs when an operator
# explicitly configures a local or hosted model.
class AiAssistantService
  GROQ_ENDPOINT = URI("https://api.groq.com/openai/v1/chat/completions").freeze
  # llama-3.3-70b-versatile: best free-tier quality on Groq. Caps: 30 req/min,
  # ~6k tok/min — fine for a single practice's members; far smarter than 8b.
  MODEL         = "llama-3.3-70b-versatile".freeze

  SYSTEM_PROMPT = <<~PROMPT.strip
    You are Sage — a warm, knowledgeable holistic wellness companion built into the Holistic Chart by Holistic Wellness Fitness LLC.

    Voice: an encouraging coach with a clinician's care for accuracy. Direct, specific, no filler, no "as an AI" disclaimers. Use the member's first name when given. Plain English; short paragraphs; lists only when steps actually help.

    You help with: holistic wellness, whole-food and anti-inflammatory nutrition, gut health and digestion, fitness and strength training, movement, sleep, stress and mindfulness, hydration, habit-building, and interpreting the member's own chart trends (vitals, check-ins, meals, workouts, BMI, goals).

    Hard rules — this is a health product:
    - You are NOT a doctor. Never diagnose, never prescribe, never tell anyone to start, stop, or change a medication. Offer general wellness education and encourage members to confirm anything medical with their care team or a licensed clinician.
    - Urgent/crisis messages (chest pain, trouble breathing, stroke signs, thoughts of self-harm) → tell them to call 911 immediately and/or call or text 988 (Suicide & Crisis Lifeline) FIRST, before anything else.
    - Never invent the member's numbers. Use only the LIVE CONTEXT provided below; if you don't have a value, say so and point them to their chart.
    - Tailor advice to the member's goal and chart when known. Be kind, non-judgmental, and body-positive.
    - Keep replies under 180 words unless the member asks for more. Reference earlier turns naturally.
  PROMPT

  # endpoint/model/api_key/timeout are injectable so the same client serves Groq
  # and any local OpenAI-compatible server. No-arg construction = Groq.
  def initialize(endpoint: GROQ_ENDPOINT, model: MODEL, api_key: ENV["GROQ_API_KEY"], timeout: 15)
    @endpoint = endpoint.is_a?(URI) ? endpoint : URI(endpoint.to_s)
    @model    = model
    @api_key  = api_key
    @timeout  = timeout
  end

  def chat(user_message, context: {})
    raise "GROQ_API_KEY missing" if @api_key.blank? && groq_endpoint?
    messages = build_messages(user_message, context)
    response = call_chat(messages)
    extract_content(response)
  end

  # Conversation-aware chat. `history` is an array of { role:, text: } hashes
  # representing earlier turns; we replay them so the model has full context.
  # Returns nil when the provider can't run (e.g. Groq without a key) so the
  # caller can fall through to the next provider.
  def chat_with_history(user_message, context: {}, history: [])
    return nil if @api_key.blank? && groq_endpoint?

    msgs = [ { role: "system", content: system_prompt_with_context(context) } ]
    Array(history).each do |turn|
      role = turn[:role] || turn["role"]
      text = (turn[:text] || turn["text"]).to_s.strip
      next if text.empty?
      msgs << { role: (role == "assistant" ? "assistant" : "user"), content: text }
    end
    # Last user turn may already be in history; if not, append it.
    if msgs.none? { |m| m[:role] == "user" && m[:content] == user_message }
      msgs << { role: "user", content: user_message }
    end

    extract_content(call_chat(msgs))
  end

  # Builds the system prompt with the member's LIVE CONTEXT. Only minimal derived
  # metrics are included — never direct identifiers — so the off-server footprint
  # stays as small as possible when a cloud model is in use.
  def system_prompt_with_context(context)
    prompt = SYSTEM_PROMPT.dup
    lines = []
    lines << "First name: #{context[:first_name]}."                                  if context[:first_name].present?
    lines << "Primary goal: #{context[:primary_goal]}."                              if context[:primary_goal].present?
    lines << "Latest wellness score: #{context[:wellness_score]}/100."               if context[:wellness_score].present?
    lines << "Latest mood/energy/stress: #{context[:mood_label]}/#{context[:energy_label]}/#{context[:stress_label]}." if context[:mood_label].present?
    lines << "Last night's sleep: #{context[:sleep_hours]} hours."                   if context[:sleep_hours].present?
    lines << "BMI: #{context[:bmi]} (#{context[:bmi_category]})."                    if context[:bmi].present?
    lines << "Last blood pressure: #{context[:blood_pressure]} (#{context[:bp_category]})." if context[:blood_pressure].present?
    lines << "Resting heart rate: #{context[:resting_hr]} bpm."                      if context[:resting_hr].present?
    lines << "Today: ~#{context[:today_calories]} of ~#{context[:calorie_target]} kcal target." if context[:calorie_target].present?
    lines << "This week: #{context[:week_minutes]} active minutes over #{context[:week_sessions]} sessions." if context[:week_minutes].present?
    lines << "Check-in streak: #{context[:streak]} days."                            if context[:streak].to_i.positive?
    lines << "Local time: #{context[:local_time]}."                                  if context[:local_time].present?
    prompt += "\n\nLIVE CONTEXT (use this — don't invent more):\n" + lines.join("\n") if lines.any?
    prompt
  end

  private

  def groq_endpoint?
    @endpoint.host == GROQ_ENDPOINT.host
  end

  def build_messages(user_message, context)
    [
      { role: "system", content: system_prompt_with_context(context) },
      { role: "user",   content: user_message }
    ]
  end

  def call_chat(messages)
    body = {
      model:       @model,
      messages:    messages,
      max_tokens:  384,        # Tighter cap = faster + stays inside 6k tok/min free-tier
      temperature: 0.4
    }.to_json

    http = Net::HTTP.new(@endpoint.host, @endpoint.port)
    http.use_ssl      = (@endpoint.scheme == "https")
    http.open_timeout = 6
    http.read_timeout = @timeout

    request = Net::HTTP::Post.new(@endpoint.request_uri)
    request["Content-Type"]  = "application/json"
    request["Authorization"] = "Bearer #{@api_key}" if @api_key.present?
    request.body = body

    response = http.request(request)
    JSON.parse(response.body)
  rescue Net::ReadTimeout, Net::OpenTimeout, SocketError, Errno::ECONNREFUSED, JSON::ParserError => e
    Rails.logger.error "[AiAssistantService] request to #{@endpoint.host} failed: #{e.message}"
    { "error" => e.message }
  end

  def extract_content(parsed)
    parsed.dig("choices", 0, "message", "content").presence || nil
  end
end
