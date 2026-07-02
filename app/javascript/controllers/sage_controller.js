import { Controller } from "@hotwired/stimulus"

// Sage — the holistic wellness assistant widget.
//
// Implemented as a Stimulus controller (served from our own origin, no inline
// <script>) so it complies with the app's strict, nonce-based Content Security
// Policy and re-connects cleanly across Turbo navigations. Talks to
// POST /api/ai/chat and renders the streamed-in reply with light markdown.
export default class extends Controller {
  static targets = ["fab", "panel", "messages", "input", "send"]
  static values = {
    avatar: String,
    url: { type: String, default: "/api/ai/chat" }
  }

  connect() {
    this.open = false
    this.loading = false
  }

  get csrf() {
    const el = document.querySelector('meta[name="csrf-token"]')
    return el ? el.content : ""
  }

  toggle() {
    this.open = !this.open
    this.fabTarget.classList.toggle("is-open", this.open)
    this.panelTarget.style.display = this.open ? "flex" : "none"
    if (this.open) setTimeout(() => this.inputTarget.focus(), 80)
  }

  keydown(event) {
    if (event.key === "Enter" && !event.shiftKey) {
      event.preventDefault()
      this.send()
    }
  }

  suggest(event) {
    const chip = event.currentTarget
    const wrap = chip.closest(".sage-suggestions")
    if (wrap) wrap.remove()
    this.inputTarget.value = chip.dataset.suggestion || ""
    this.send()
  }

  async send() {
    const message = this.inputTarget.value.trim()
    if (!message || this.loading) return

    this.append(message, "user")
    this.inputTarget.value = ""
    this.loading = true
    this.sendTarget.disabled = true
    const typing = this.appendTyping()

    try {
      const response = await fetch(this.urlValue, {
        method: "POST",
        headers: { "Content-Type": "application/json", "X-CSRF-Token": this.csrf },
        body: JSON.stringify({ message })
      })
      const data = await response.json()
      typing.remove()
      this.append(response.ok ? (data.reply || "") : (data.error || "Something went wrong."), "bot")
    } catch (error) {
      typing.remove()
      this.append("Connection trouble — please check your network and try again.", "bot")
    } finally {
      this.loading = false
      this.sendTarget.disabled = false
    }
  }

  // ── rendering helpers ──────────────────────────────────────────────────────

  append(text, role) {
    const el = document.createElement("div")
    el.className = `sage-msg sage-msg--${role}`
    if (role === "bot") {
      el.innerHTML = `${this.avatarMarkup()}<div><div class="sage-msg-bubble">${this.markdown(text)}</div></div>`
    } else {
      el.innerHTML = `<div class="sage-msg-bubble">${this.escape(text).replace(/\n/g, "<br>")}</div>`
    }
    this.messagesTarget.appendChild(el)
    this.scrollToEnd()
  }

  appendTyping() {
    const el = document.createElement("div")
    el.className = "sage-msg sage-msg--bot"
    el.innerHTML = `${this.avatarMarkup()}<div><div class="sage-msg-bubble"><span class="sage-typing"><span></span><span></span><span></span></span></div></div>`
    this.messagesTarget.appendChild(el)
    this.scrollToEnd()
    return el
  }

  avatarMarkup() {
    return `<span class="sage-msg-av" aria-hidden="true"><img src="${this.avatarValue}" alt=""></span>`
  }

  scrollToEnd() {
    setTimeout(() => { this.messagesTarget.scrollTop = this.messagesTarget.scrollHeight }, 30)
  }

  escape(value) {
    return String(value == null ? "" : value)
      .replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;")
  }

  // Minimal, safe markdown: bold, italics, bullet/numbered lists, line breaks.
  markdown(text) {
    return this.escape(text)
      .replace(/\*\*(.+?)\*\*/g, "<strong>$1</strong>")
      .replace(/_(.+?)_/g, "<em>$1</em>")
      .replace(/^[-•]\s+(.+)$/gm, "<li>$1</li>")
      .replace(/^\d+\.\s+(.+)$/gm, "<li>$1</li>")
      .replace(/(<li>[\s\S]*?<\/li>\n?)+/g, (m) => `<ul class="sage-list">${m}</ul>`)
      .replace(/\n/g, "<br>")
  }
}
