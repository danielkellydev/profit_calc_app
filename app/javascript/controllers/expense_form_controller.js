import { Controller } from "@hotwired/stimulus"

// Toggles the date-field labels and end-date visibility based on the frequency.
// For 'one_off': hides end-date, relabels start-date as "Purchase date" (required).
// For recurring frequencies: shows the optional start/end range.
export default class extends Controller {
  static targets = ["frequency", "endDate", "oneOffLabel", "recurringStartLabel"]

  connect() {
    this.toggle()
  }

  toggle() {
    if (!this.hasFrequencyTarget) return
    const oneOff = this.frequencyTarget.value === "one_off"
    if (this.hasEndDateTarget) this.endDateTarget.classList.toggle("hidden", oneOff)
    if (this.hasOneOffLabelTarget) this.oneOffLabelTarget.classList.toggle("hidden", !oneOff)
    if (this.hasRecurringStartLabelTarget) this.recurringStartLabelTarget.classList.toggle("hidden", oneOff)
  }
}
