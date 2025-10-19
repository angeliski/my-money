import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form"]

  connect() {
    this.timeout = null
  }

  submit(event) {
    if (this.hasFormTarget) {
      this.formTarget.requestSubmit()
    }
  }

  debounceSubmit(event) {
    clearTimeout(this.timeout)
    this.timeout = setTimeout(() => {
      if (this.hasFormTarget) {
        this.formTarget.requestSubmit()
      }
    }, 300) // 300ms debounce
  }
}
