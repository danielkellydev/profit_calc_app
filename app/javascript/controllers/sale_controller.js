import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["saleTypeInput", "saleTypeCard", "quantityInput", "quantityDisplay"]

  connect() {
    const initialSaleTypeId = this.saleTypeInputTarget.value
    if (initialSaleTypeId) {
      const selectedCard = this.saleTypeCardTargets.find(card => card.dataset.saleTypeId === initialSaleTypeId)
      if (selectedCard) {
        selectedCard.classList.add('border-blue-500', 'border-2')
      }
    }
  }

  selectSaleType(event) {
    const saleTypeId = event.currentTarget.dataset.saleTypeId
    this.saleTypeInputTarget.value = saleTypeId
    
    // Remove 'selected' class from all cards
    this.saleTypeCardTargets.forEach(card => {
      card.classList.remove('border-blue-500', 'border-2')
    })
    
    // Add 'selected' class to the clicked card
    event.currentTarget.classList.add('border-blue-500', 'border-2')
  }

  incrementProduct(event) {
    event.preventDefault()
    const productId = event.currentTarget.dataset.productId
    const input = document.getElementById(`quantity_${productId}`)
    const display = document.getElementById(`quantity_display_${productId}`)
    const currentValue = parseInt(input.value) || 0
    input.value = currentValue + 1
    if (display) {
      display.textContent = input.value
    }
  }

  decrementProduct(event) {
    event.preventDefault()
    const productId = event.currentTarget.dataset.productId
    const input = document.getElementById(`quantity_${productId}`)
    const display = document.getElementById(`quantity_display_${productId}`)
    const currentValue = parseInt(input.value) || 0
    if (currentValue > 0) {
      input.value = currentValue - 1
      if (display) {
        display.textContent = input.value
      }
    }
  }
}