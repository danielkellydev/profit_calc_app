import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    if (this.element.querySelector('#xero-account-select')) {
      this.loadAccounts()
    }
  }

  toggleSync(event) {
    const accountFields = document.getElementById('xero-account-fields')
    if (event.target.checked) {
      accountFields.classList.remove('hidden')
      this.loadAccounts()
    } else {
      accountFields.classList.add('hidden')
    }
  }

  async loadAccounts() {
    const select = document.getElementById('xero-account-select')
    if (!select) return
    
    try {
      const response = await fetch('/xero/accounts')
      if (response.ok) {
        const accounts = await response.json()
        
        // Clear existing options
        select.innerHTML = '<option value="">Select an account...</option>'
        
        // Group accounts by type
        const groupedAccounts = {}
        accounts.forEach(account => {
          if (!groupedAccounts[account.type]) {
            groupedAccounts[account.type] = []
          }
          groupedAccounts[account.type].push(account)
        })
        
        // Add grouped options
        Object.keys(groupedAccounts).sort().forEach(type => {
          const optgroup = document.createElement('optgroup')
          optgroup.label = type
          
          groupedAccounts[type].forEach(account => {
            const option = document.createElement('option')
            option.value = account.code
            option.textContent = `${account.code} - ${account.name}`
            option.dataset.accountName = account.name
            optgroup.appendChild(option)
          })
          
          select.appendChild(optgroup)
        })
        
        // Set current value if it exists
        const currentCode = document.getElementById('sale_type_xero_account_code').value
        if (currentCode) {
          select.value = currentCode
        }
      } else if (response.status === 401) {
        select.innerHTML = '<option value="">Not connected to Xero</option>'
      } else {
        select.innerHTML = '<option value="">Error loading accounts</option>'
      }
    } catch (error) {
      console.error('Error loading Xero accounts:', error)
      select.innerHTML = '<option value="">Error loading accounts</option>'
    }
  }

  selectAccount(event) {
    const select = event.target
    const selectedOption = select.options[select.selectedIndex]
    
    document.getElementById('sale_type_xero_account_code').value = select.value
    document.getElementById('sale_type_xero_account_name').value = selectedOption.dataset.accountName || ''
  }
}