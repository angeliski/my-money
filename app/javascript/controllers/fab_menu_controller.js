import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="fab-menu"
export default class extends Controller {
  static targets = ["menu", "overlay"]

  connect() {
    this.menuOpen = false
  }

  toggle(event) {
    event.preventDefault()
    event.stopPropagation()

    if (this.menuOpen) {
      this.close()
    } else {
      this.open()
    }
  }

  open() {
    this.menuOpen = true

    // Criar overlay
    const overlay = document.createElement('div')
    overlay.classList.add('fixed', 'inset-0', 'bg-black/50', 'z-40', 'fab-overlay')
    overlay.addEventListener('click', () => this.close())
    document.body.appendChild(overlay)

    // Criar menu radial
    const menu = this.createRadialMenu()
    document.body.appendChild(menu)

    // Animação de entrada
    requestAnimationFrame(() => {
      overlay.style.opacity = '1'
      overlay.style.transition = 'opacity 0.2s'
      menu.querySelectorAll('.fab-menu-item').forEach((item, index) => {
        setTimeout(() => {
          item.style.opacity = '1'
          item.style.transform = 'translateX(-50%) scale(1)'
        }, index * 50)
      })
    })

    // Trocar ícone do FAB para X
    this.element.innerHTML = `
      <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path>
      </svg>
    `
  }

  close() {
    this.menuOpen = false

    const overlay = document.querySelector('.fab-overlay')
    const menu = document.querySelector('.fab-radial-menu')

    if (overlay) {
      overlay.style.opacity = '0'
      setTimeout(() => overlay.remove(), 200)
    }

    if (menu) {
      menu.querySelectorAll('.fab-menu-item').forEach(item => {
        item.style.opacity = '0'
        item.style.transform = 'translateX(-50%) scale(0.8)'
      })
      setTimeout(() => menu.remove(), 200)
    }

    // Trocar ícone de volta para +
    this.element.innerHTML = `
      <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"></path>
      </svg>
    `
  }

  createRadialMenu() {
    const menu = document.createElement('div')
    menu.classList.add('fab-radial-menu', 'fixed', 'z-50')

    // Posicionar no canto inferior direito (acima do FAB)
    const fabRect = this.element.getBoundingClientRect()
    menu.style.bottom = `${window.innerHeight - fabRect.top + 20}px`
    menu.style.right = `${window.innerWidth - fabRect.right + fabRect.width/2}px`

    const options = [
      {
        label: 'Receita',
        icon: '↑',
        color: 'bg-[#10B981]',
        position: { x: -100, y: 15 },
        href: '/transactions/new?type=income'
      },
      {
        label: 'Despesa',
        icon: '↓',
        color: 'bg-[#F87171]',
        position: { x: -50, y: 80 },
        href: '/transactions/new?type=expense'
      },
      {
        label: 'Transferência',
        icon: '⇄',
        color: 'bg-[#8B5CF6]',
        position: { x: 40, y: 80 },
        href: '/transfers/new'
      }
    ]

    options.forEach(option => {
      const item = document.createElement('a')
      if (option.disabled) {
        item.classList.add('fab-menu-item', 'absolute', 'flex', 'flex-col', 'items-center', 'gap-1')
        item.style.pointerEvents = 'none'
      } else {
        item.href = option.href
        item.setAttribute('data-turbo-frame', 'transaction_modal')
        item.classList.add('fab-menu-item', 'absolute', 'flex', 'flex-col', 'items-center', 'gap-1', 'cursor-pointer')

        // Fechar menu ao clicar
        item.addEventListener('click', () => {
          setTimeout(() => this.close(), 100)
        })
      }

      item.style.transform = 'translateX(-50%)'
      item.style.left = `${option.position.x}px`
      item.style.bottom = `${option.position.y}px`
      item.style.opacity = '0'
      item.style.transition = 'all 0.2s'

      item.innerHTML = `
        <span class="text-xs text-white font-medium bg-black/70 px-2 py-1 rounded whitespace-nowrap mb-1">${option.label}</span>
        <div class="w-12 h-12 ${option.color} hover:opacity-90 rounded-full shadow-lg flex items-center justify-center text-white text-2xl">
          ${option.icon}
        </div>
      `

      menu.appendChild(item)
    })

    return menu
  }
}
