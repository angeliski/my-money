import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["content"]

  connect() {
    // Adicionar listener para ESC key
    this.escapeHandler = this.handleEscape.bind(this)
    document.addEventListener("keydown", this.escapeHandler)
  }

  disconnect() {
    document.removeEventListener("keydown", this.escapeHandler)
  }

  handleEscape(event) {
    if (event.key === "Escape") {
      this.close()
    }
  }

  closeBackground(event) {
    if (event.target === this.element) {
      this.close()
    }
  }

  stopPropagation(event) {
    event.stopPropagation()
  }

  close(event) {
    if (event) {
      event.preventDefault()
    }
    this.element.remove()
  }
}
