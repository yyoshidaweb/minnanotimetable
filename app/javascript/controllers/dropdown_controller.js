import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu", "urlInput", "copyMessage"]

  connect() {
    document.addEventListener('click', this.handleClickOutside.bind(this))
  }

  disconnect() {
    document.removeEventListener('click', this.handleClickOutside.bind(this))
  }

  toggle() {
    this.menuTarget.classList.toggle('hidden')
  }

  handleClickOutside(event) {
    if (!this.element.contains(event.target)) {
      this.menuTarget.classList.add('hidden')
      this.hideCopyMessage()
    }
  }

  // URLをクリップボードにコピー
  async copyUrl(event) {
    try {
      await navigator.clipboard.writeText(this.urlInputTarget.value)
      this.showCopyMessage()
    } catch (err) {
      console.error('Failed to copy:', err)
    }
  }

  // コピー完了メッセージを表示
  showCopyMessage() {
    this.copyMessageTarget.classList.remove('hidden')
    setTimeout(() => {
      this.hideCopyMessage()
    }, 3000)
  }

  // コピー完了メッセージを非表示
  hideCopyMessage() {
    this.copyMessageTarget.classList.add('hidden')
  }
}
