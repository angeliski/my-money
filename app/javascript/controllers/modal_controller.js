import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["content"]

  connect() {
    this.element.addEventListener("click", this.handleBackdropClick.bind(this))
  }

  disconnect() {
    this.element.removeEventListener("click", this.handleBackdropClick.bind(this))
  }

  handleBackdropClick(event) {
    if (event.target === this.element) {
      this.close()
    }
  }

  close() {
    this.element.remove()
  }
}
