import { Controller } from "@hotwired/stimulus"

// Drives the first-run walkthrough: shows one step at a time with Back/Next,
// a progress bar and dots. The final step reveals the legal acceptance + finish.
export default class extends Controller {
  static targets = ["step", "dot", "back", "next", "finish", "progress", "counter"]

  connect() {
    this.index = 0
    this.render()
  }

  next() {
    if (this.index < this.stepTargets.length - 1) {
      this.index++
      this.render()
    }
  }

  back() {
    if (this.index > 0) {
      this.index--
      this.render()
    }
  }

  render() {
    const last = this.index === this.stepTargets.length - 1
    this.stepTargets.forEach((el, i) => el.classList.toggle("d-none", i !== this.index))
    if (this.hasDotTarget) {
      this.dotTargets.forEach((el, i) => el.classList.toggle("is-active", i === this.index))
    }
    if (this.hasBackTarget) this.backTarget.classList.toggle("invisible", this.index === 0)
    if (this.hasNextTarget) this.nextTarget.classList.toggle("d-none", last)
    if (this.hasFinishTarget) this.finishTarget.classList.toggle("d-none", !last)
    if (this.hasProgressTarget) {
      this.progressTarget.style.width = `${((this.index + 1) / this.stepTargets.length) * 100}%`
    }
    if (this.hasCounterTarget) {
      this.counterTarget.textContent = `${this.index + 1} / ${this.stepTargets.length}`
    }
  }
}
