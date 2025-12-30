import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="modal"
export default class extends Controller {
  // モーダルをクローズする
  close() {
    // モーダル全体を取得
    const frame = this.element.closest("turbo-frame")
    // モーダル全体の中身を空にする
    if (frame) frame.innerHTML = ""
  }

  // 背景への click 伝播を止める
  stop(event) {
    event.stopPropagation()
  }
}
