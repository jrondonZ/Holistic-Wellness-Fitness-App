// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"

// Animate-on-scroll (library is loaded from the CDN and exposed as window.AOS).
document.addEventListener("turbo:load", () => {
  if (window.AOS) window.AOS.init({ duration: 700, once: true, offset: 40 })
})

// Optional client-side deterrent, enabled only in production via a meta flag.
// NOTE: this is NOT a security control — browser developer tools cannot truly
// be disabled, and this only discourages casual right-click/inspect. The real
// protections live server-side (CSP, authentication, security headers, CSRF).
if (document.querySelector('meta[name="app-guard"][content="on"]')) {
  document.addEventListener("contextmenu", (event) => event.preventDefault())
  document.addEventListener("keydown", (event) => {
    const key = (event.key || "").toUpperCase()
    const blocked =
      event.key === "F12" ||
      (event.ctrlKey && event.shiftKey && ["I", "J", "C"].includes(key)) ||
      (event.ctrlKey && key === "U") ||
      (event.metaKey && event.altKey && ["I", "J", "C"].includes(key))
    if (blocked) event.preventDefault()
  })
}
