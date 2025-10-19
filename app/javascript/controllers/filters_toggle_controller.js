import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["content", "icon", "label"]

  toggle() {
    const isHidden = this.contentTarget.classList.contains("hidden")

    this.contentTarget.classList.toggle("hidden")

    if (isHidden) {
      this.iconTarget.textContent = "🔼"
      this.labelTarget.textContent = "Ocultar filtros"
    } else {
      this.iconTarget.textContent = "🔽"
      this.labelTarget.textContent = "Mostrar filtros"
    }
  }
}
