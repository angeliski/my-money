import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["name", "nameError", "balance", "balanceError"]

  connect() {
    console.log("Account form controller connected")
  }

  validateName(event) {
    const name = this.nameTarget.value.trim()

    if (name === "") {
      this.showError(this.nameErrorTarget, "Nome não pode ficar em branco")
      return false
    }

    if (name.length > 50) {
      this.showError(this.nameErrorTarget, "Nome não pode ter mais de 50 caracteres")
      return false
    }

    this.hideError(this.nameErrorTarget)
    return true
  }

  formatCurrency(event) {
    let value = this.balanceTarget.value

    // Remove tudo exceto números, vírgula e sinal negativo
    value = value.replace(/[^\d,-]/g, '')

    // Captura o sinal negativo
    const isNegative = value.startsWith('-')
    value = value.replace(/-/g, '')

    // Separa parte inteira e decimal
    let parts = value.split(',')
    let integerPart = parts[0]
    let decimalPart = parts[1] || ''

    // Limita decimais a 2 dígitos
    if (decimalPart.length > 2) {
      decimalPart = decimalPart.substring(0, 2)
    }

    // Adiciona separador de milhares na parte inteira
    if (integerPart.length > 0) {
      integerPart = integerPart.replace(/\B(?=(\d{3})+(?!\d))/g, '.')
    }

    // Reconstrói o valor
    value = integerPart
    if (parts.length > 1 || decimalPart.length > 0) {
      value += ',' + decimalPart
    }

    if (isNegative && value !== '' && value !== ',') {
      value = '-' + value
    }

    this.balanceTarget.value = value
  }

  validateBalance(event) {
    const balance = this.balanceTarget.value.trim()

    if (balance === "" || balance === "-" || balance === ",") {
      this.showError(this.balanceErrorTarget, "Saldo inicial é obrigatório")
      return false
    }

    // Aceita formato brasileiro: 1.234,56 ou -1.234,56 ou 1234,56 ou 1234
    if (!/^-?(\d{1,3}(\.\d{3})*)(\,\d{1,2})?$/.test(balance)) {
      this.showError(this.balanceErrorTarget, "Formato inválido. Use: 18.456,77")
      return false
    }

    this.hideError(this.balanceErrorTarget)
    return true
  }

  validateForm(event) {
    const nameValid = this.validateName()
    const balanceValid = this.validateBalance()

    if (!nameValid || !balanceValid) {
      event.preventDefault()
      return false
    }

    return true
  }

  showError(target, message) {
    target.textContent = message
    target.classList.remove("hidden")
  }

  hideError(target) {
    target.classList.add("hidden")
  }
}
