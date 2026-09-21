import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="overflow-menu"
// ボタン押下でオーバーフローメニューを開閉する
export default class extends Controller {
  static targets = [ "menu", "button" ]

  connect() {
    this.boundCloseOnOutside = this.closeOnOutside.bind(this)
    this.boundCloseOnEscape = this.closeOnEscape.bind(this)
  }

  disconnect() {
    this.removeDocumentListeners()
  }

  toggle(event) {
    event.stopPropagation()
    if (this.menuTarget.hidden) {
      this.open()
    } else {
      this.close()
    }
  }

  open() {
    this.menuTarget.hidden = false
    this.buttonTarget.setAttribute("aria-expanded", "true")
    document.addEventListener("click", this.boundCloseOnOutside)
    document.addEventListener("keydown", this.boundCloseOnEscape)
  }

  close() {
    this.menuTarget.hidden = true
    this.buttonTarget.setAttribute("aria-expanded", "false")
    this.removeDocumentListeners()
  }

  closeOnOutside(event) {
    if (!this.element.contains(event.target)) {
      this.close()
    }
  }

  closeOnEscape(event) {
    if (event.key === "Escape") {
      this.close()
    }
  }

  removeDocumentListeners() {
    document.removeEventListener("click", this.boundCloseOnOutside)
    document.removeEventListener("keydown", this.boundCloseOnEscape)
  }
}
