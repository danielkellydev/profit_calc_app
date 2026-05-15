import { Controller } from "@hotwired/stimulus"

// Suggests a business-use % from "rooms used / total rooms".
// Does not auto-fill — user clicks "apply" to copy the value into the field.
export default class extends Controller {
  static targets = ["used", "total", "suggestion", "result"]

  connect() {
    if (this.hasUsedTarget && this.hasTotalTarget) this.calc()
  }

  calc() {
    const used = parseFloat(this.usedTarget.value)
    const total = parseFloat(this.totalTarget.value)
    if (!isFinite(used) || !isFinite(total) || total <= 0) {
      this.suggestionTarget.textContent = "—"
      this.suggestion = null
      return
    }
    const pct = Math.min(100, Math.max(0, (used / total) * 100))
    this.suggestion = pct.toFixed(1)
    this.suggestionTarget.textContent = `${this.suggestion}%`
  }

  apply() {
    if (this.suggestion != null && this.hasResultTarget) {
      this.resultTarget.value = this.suggestion
    }
  }
}
