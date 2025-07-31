// app/javascript/controllers/tab_controller.js

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["button", "content"]

  connect() {
    console.log("Tab controller connected")
    this.initializeTabs()
  }

  initializeTabs() {
    console.log('Initializing tabs')
    if (this.buttonTargets.length === 0 || this.contentTargets.length === 0) {
      console.warn('Tab buttons or contents not found. Skipping initialization.')
      return
    }

    // Show weekly tab by default
    this.showTab('weekly')
  }

  switch(event) {
    const tab = event.currentTarget.dataset.tab
    this.showTab(tab)
  }

  showTab(tabId) {
    const targetContent = this.contentTargets.find(el => el.id === tabId)
    const targetButton = this.buttonTargets.find(btn => btn.dataset.tab === tabId)
    
    if (!targetContent || !targetButton) {
      console.warn(`Tab content or button for ${tabId} not found.`)
      return
    }
    
    this.buttonTargets.forEach(btn => btn.classList.remove('text-blue-600', 'border-blue-500', 'active'))
    this.contentTargets.forEach(content => content.classList.add('hidden'))
    
    targetButton.classList.add('text-blue-600', 'border-blue-500', 'active')
    targetContent.classList.remove('hidden')
  }
}