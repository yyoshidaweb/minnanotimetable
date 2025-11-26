import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["textarea"]

  connect() {
    this.adjustHeight()
  }

  adjustHeight() {
    this.textareaTargets.forEach((el) => {
      el.style.height = "auto"             // 一旦リセット
      el.style.height = el.scrollHeight + "px" // 内容に合わせる
    })
  }

  resize(event) {
    const el = event.target
    el.style.height = "auto"
    el.style.height = el.scrollHeight + "px"
  }
}
