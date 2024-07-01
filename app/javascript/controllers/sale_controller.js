import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  handleSaleTypeChange(event) {
    if (event.target.value === "new_sale_type") {
      window.location.href = "/sale_types/new"
    }
  }
}