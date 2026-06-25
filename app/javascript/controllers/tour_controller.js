import { Controller } from "@hotwired/stimulus"

// Interactive spotlight walkthrough. Reads a list of steps (selector + copy),
// dims the page, highlights the real target element, and shows a positioned
// card with Back / Next / Skip. On finish it POSTs to mark the tutorial done.
export default class extends Controller {
  static values = { steps: Array, completeUrl: String, autostart: Boolean }

  connect() {
    this.index = 0
    if (this.autostartValue && this.stepsValue.length) {
      // Let the page settle before measuring element positions.
      this.timer = setTimeout(() => this.start(), 450)
    }
  }

  disconnect() {
    clearTimeout(this.timer)
    this.teardown()
  }

  start() {
    this.backdrop = document.createElement("div")
    this.backdrop.className = "tour-backdrop"
    document.body.appendChild(this.backdrop)

    this.pop = document.createElement("div")
    this.pop.className = "tour-pop"
    document.body.appendChild(this.pop)

    this.render()
    window.addEventListener("resize", this.reposition)
  }

  render() {
    this.clearHighlight()
    const step = this.stepsValue[this.index]
    const target = step.target ? document.querySelector(step.target) : null
    this.current = target

    if (target) {
      target.classList.add("tour-highlight")
      target.scrollIntoView({ behavior: "smooth", block: "center" })
    }

    const dots = this.stepsValue.map((_, i) => `<i class="${i === this.index ? "on" : ""}"></i>`).join("")
    const last = this.index === this.stepsValue.length - 1
    this.pop.innerHTML = `
      <div class="tour-meta mb-1">Step ${this.index + 1} of ${this.stepsValue.length}</div>
      <h4>${step.title}</h4>
      <p class="text-muted small mb-3">${step.body}</p>
      <div class="d-flex align-items-center justify-content-between">
        <span class="tour-dots">${dots}</span>
        <span class="d-flex gap-2">
          <button type="button" class="btn btn-link btn-sm text-muted p-0 me-2" data-act="skip">Skip</button>
          ${this.index > 0 ? '<button type="button" class="btn btn-outline-brand btn-sm" data-act="back">Back</button>' : ""}
          <button type="button" class="btn btn-brand btn-sm" data-act="next">${last ? "Finish" : "Next"}</button>
        </span>
      </div>`

    this.pop.querySelectorAll("[data-act]").forEach((b) => {
      b.addEventListener("click", () => this.act(b.dataset.act))
    })
    requestAnimationFrame(() => this.reposition())
  }

  act(action) {
    if (action === "skip") return this.finish()
    if (action === "back") { this.index = Math.max(0, this.index - 1); return this.render() }
    if (this.index === this.stepsValue.length - 1) return this.finish()
    this.index += 1
    this.render()
  }

  reposition = () => {
    if (!this.pop) return
    const pop = this.pop.getBoundingClientRect()
    const margin = 14
    if (!this.current) {
      this.pop.style.top = `${Math.max(margin, (window.innerHeight - pop.height) / 2)}px`
      this.pop.style.left = `${(window.innerWidth - pop.width) / 2}px`
      return
    }
    const rect = this.current.getBoundingClientRect()
    let top = rect.bottom + margin
    if (top + pop.height > window.innerHeight - margin) {
      top = Math.max(margin, rect.top - pop.height - margin)
    }
    let left = rect.left
    if (left + pop.width > window.innerWidth - margin) left = window.innerWidth - pop.width - margin
    this.pop.style.top = `${Math.max(margin, top)}px`
    this.pop.style.left = `${Math.max(margin, left)}px`
  }

  clearHighlight() {
    if (this.current) this.current.classList.remove("tour-highlight")
  }

  finish() {
    this.teardown()
    const token = document.querySelector('meta[name="csrf-token"]')?.content
    if (this.completeUrlValue && token) {
      fetch(this.completeUrlValue, {
        method: "POST",
        headers: { "X-CSRF-Token": token, "Accept": "text/plain" },
        credentials: "same-origin"
      }).catch(() => {})
    }
  }

  teardown() {
    window.removeEventListener("resize", this.reposition)
    this.clearHighlight()
    this.backdrop?.remove()
    this.pop?.remove()
    this.backdrop = null
    this.pop = null
  }
}
