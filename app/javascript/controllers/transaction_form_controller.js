import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "recurringOptions",
    "occurrencesDisplay",
    "occurrencesInput"
  ]

  connect() {
    this.updateRecurringOptions()
  }

  toggleRecurring(event) {
    this.updateRecurringOptions()
  }

  updateRecurringOptions() {
    const checkbox = this.element.querySelector('input[type="checkbox"][name="transaction[is_template]"]')
    const frequencySelect = this.element.querySelector('select[name="transaction[frequency]"]')

    if (this.hasRecurringOptionsTarget && checkbox) {
      this.recurringOptionsTarget.classList.toggle("hidden", !checkbox.checked)

      // Disable frequency field when recurring is off
      if (frequencySelect) {
        frequencySelect.disabled = !checkbox.checked
        // Clear frequency value when disabled
        if (!checkbox.checked) {
          frequencySelect.value = ''
        }
      }
    }
  }

  incrementOccurrences(event) {
    event.preventDefault()
    const current = parseInt(this.occurrencesInputTarget.value) || 2
    const newValue = Math.min(current + 1, 24) // Max 24 occurrences
    this.occurrencesInputTarget.value = newValue
    this.occurrencesDisplayTarget.textContent = newValue
  }

  decrementOccurrences(event) {
    event.preventDefault()
    const current = parseInt(this.occurrencesInputTarget.value) || 2
    const newValue = Math.max(current - 1, 2) // Min 2 occurrences
    this.occurrencesInputTarget.value = newValue
    this.occurrencesDisplayTarget.textContent = newValue
  }
}
