import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="money-input"
export default class extends Controller {
  static targets = ["input", "hiddenInput"]

  connect() {
    // Inicializar com valor existente se houver
    if (this.hiddenInputTarget.value) {
      const cents = parseInt(this.hiddenInputTarget.value)
      const reais = cents / 100
      this.inputTarget.value = this.formatDisplay(reais)
      this.updateHeader()
    }
  }

  format(event) {
    const input = event.target
    let value = input.value

    // Remover tudo que não é número
    value = value.replace(/\D/g, '')

    if (value === '') {
      input.value = ''
      this.hiddenInputTarget.value = ''
      this.updateHeader()
      return
    }

    // Converter para número (em centavos)
    const cents = parseInt(value)

    // Converter para reais
    const reais = cents / 100

    // Atualizar display
    input.value = this.formatDisplay(reais)

    // Atualizar campo hidden (em centavos)
    this.hiddenInputTarget.value = cents

    // Atualizar header visual
    this.updateHeader()
  }

  updateHeader() {
    const header = document.getElementById('amount-display-header')
    if (header) {
      const value = this.inputTarget.value || '0,00'
      header.textContent = `R$ ${value}`
    }
  }

  formatDisplay(value) {
    return value.toLocaleString('pt-BR', {
      minimumFractionDigits: 2,
      maximumFractionDigits: 2
    })
  }
}
