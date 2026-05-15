import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["status"]

  async run() {
    this.statusTarget.textContent = "Testing…"
    this.statusTarget.className = "text-sm text-gray-600"
    try {
      const response = await fetch("/woocommerce_config/test_connection", {
        method: "POST",
        headers: {
          "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content,
          "Accept": "application/json"
        }
      })
      const data = await response.json()
      this.statusTarget.textContent = data.message
      this.statusTarget.className = `text-sm ${data.ok ? "text-green-600" : "text-red-600"}`
    } catch (e) {
      this.statusTarget.textContent = "Network error"
      this.statusTarget.className = "text-sm text-red-600"
    }
  }
}
