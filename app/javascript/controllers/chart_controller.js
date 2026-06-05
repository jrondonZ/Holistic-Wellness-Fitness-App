import { Controller } from "@hotwired/stimulus"
import Chart from "chart.js/auto"

// Renders a small brand-styled trend chart (line or bar) from a JSON payload.
//
//   <div data-controller="chart"
//        data-chart-payload-value="<%= trend_payload(@series, label: 'Weight', color: '#4a7c59') %>">
//     <canvas data-chart-target="canvas"></canvas>
//   </div>
export default class extends Controller {
  static targets = ["canvas"]
  static values = { payload: Object }

  connect() {
    const data = this.payloadValue
    if (!data || !Array.isArray(data.values) || data.values.length === 0) {
      this.element.classList.add("chart-empty")
      return
    }
    this.draw(data)
  }

  disconnect() {
    if (this.chart) this.chart.destroy()
  }

  draw(data) {
    const ctx = this.canvasTarget.getContext("2d")
    const color = data.color || "#4a7c59"
    const isBar = data.type === "bar"

    const fill = ctx.createLinearGradient(0, 0, 0, 200)
    fill.addColorStop(0, this.rgba(color, 0.35))
    fill.addColorStop(1, this.rgba(color, 0.02))

    Chart.defaults.font.family = "'Inter', system-ui, sans-serif"
    Chart.defaults.color = "#6b6b6b"

    this.chart = new Chart(ctx, {
      type: data.type || "line",
      data: {
        labels: data.labels,
        datasets: [{
          label: data.label,
          data: data.values,
          borderColor: color,
          backgroundColor: isBar ? this.rgba(color, 0.85) : fill,
          fill: !isBar,
          tension: 0.38,
          borderWidth: isBar ? 0 : 3,
          pointRadius: isBar ? 0 : 3,
          pointHoverRadius: 5,
          pointBackgroundColor: color,
          borderRadius: isBar ? 8 : 0,
          maxBarThickness: 30
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        animation: { duration: 700 },
        plugins: {
          legend: { display: false },
          tooltip: {
            backgroundColor: "#2d4a30",
            padding: 10,
            cornerRadius: 10,
            displayColors: false
          }
        },
        scales: {
          x: { grid: { display: false }, border: { display: false } },
          y: {
            grace: "8%",
            grid: { color: "rgba(45,74,48,0.07)" },
            border: { display: false },
            ticks: { maxTicksLimit: 5 }
          }
        }
      }
    })
  }

  rgba(hex, alpha) {
    const clean = hex.replace("#", "")
    const r = parseInt(clean.substring(0, 2), 16)
    const g = parseInt(clean.substring(2, 4), 16)
    const b = parseInt(clean.substring(4, 6), 16)
    return `rgba(${r}, ${g}, ${b}, ${alpha})`
  }
}
