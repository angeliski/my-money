import { Controller } from "@hotwire/stimulus"

export default class extends Controller {
  static targets = ["recurringFields", "recurringOptions"]

  connect() {
    this.checkRecurringState()
  }

  toggleType(event) {
    // Handle transaction type toggle if needed
  }

  toggleRecurring(event) {
    this.checkRecurringState()
  }

  checkRecurringState() {
    const checkbox = this.element.querySelector('[name="transaction[is_template]"]')

    if (this.hasRecurringFieldsTarget) {
      this.recurringFieldsTarget.classList.toggle("hidden", false)
    }

    if (this.hasRecurringOptionsTarget && checkbox) {
      this.recurringOptionsTarget.classList.toggle("hidden", !checkbox.checked)
    }
  }
}
