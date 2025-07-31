import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "menu" ]

  connect() {
    this.clickOutside = this.clickOutside.bind(this)
  }

  toggle(event) {
    event.stopPropagation()
    this.menuTarget.classList.toggle("hidden")
    
    if (!this.menuTarget.classList.contains("hidden")) {
      document.addEventListener("click", this.clickOutside)
    } else {
      document.removeEventListener("click", this.clickOutside)
    }
  }

  clickOutside(event) {
    if (!this.element.contains(event.target)) {
      this.menuTarget.classList.add("hidden")
      document.removeEventListener("click", this.clickOutside)
    }
  }

  disconnect() {
    document.removeEventListener("click", this.clickOutside)
  }
}