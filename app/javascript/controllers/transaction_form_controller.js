import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["recurringOptions", "accountField", "transferFields"]

  connect() {
    this.updateRecurringOptions()
    this.updateAccountFields()
  }

  toggleType(event) {
    const selectedType = this.element.querySelector('input[name="transaction[transaction_type]"]:checked')?.value

    // Se transferência foi selecionada, redirecionar para o formulário de transferência
    if (selectedType === "transfer") {
      // Usar Turbo para navegação sem recarregar a página
      Turbo.visit("/transfers/new")
      return
    }

    this.updateAccountFields()
  }

  toggleRecurring(event) {
    this.updateRecurringOptions()
  }

  updateRecurringOptions() {
    const checkbox = this.element.querySelector('input[type="checkbox"][name="transaction[is_template]"]')

    if (this.hasRecurringOptionsTarget && checkbox) {
      this.recurringOptionsTarget.classList.toggle("hidden", !checkbox.checked)
    }
  }

  updateAccountFields() {
    const selectedType = this.element.querySelector('input[name="transaction[transaction_type]"]:checked')?.value

    if (!this.hasAccountFieldTarget || !this.hasTransferFieldsTarget) return

    if (selectedType === "transfer") {
      // Mostrar campos de transferência
      this.accountFieldTarget.classList.add("hidden")
      this.transferFieldsTarget.classList.remove("hidden")

      // Habilitar campos de transferência e desabilitar campo normal
      this.transferFieldsTarget.querySelectorAll("select").forEach(select => select.disabled = false)
      this.accountFieldTarget.querySelector("select").disabled = true
    } else {
      // Mostrar campo de conta normal
      this.accountFieldTarget.classList.remove("hidden")
      this.transferFieldsTarget.classList.add("hidden")

      // Habilitar campo normal e desabilitar campos de transferência
      this.accountFieldTarget.querySelector("select").disabled = false
      this.transferFieldsTarget.querySelectorAll("select").forEach(select => select.disabled = true)
    }
  }
}
