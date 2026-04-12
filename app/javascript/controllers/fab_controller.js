import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="fab"
export default class extends Controller {
  // FABメニューを展開する
  open(event) {
    event.preventDefault() // linkの遷移を止める
    const url = event.currentTarget.dataset.url // 開きたいURLを取得
    const frame = document.getElementById("modal") // layoutに置くturbo-frame
    if (frame) frame.src = url // Turboで内容を読み込む
  }

  // メニューをクローズする
  close() {
    // メニュー全体を取得
    const frame = this.element.closest("turbo-frame")
    // メニュー全体の中身を空にする
    if (frame) frame.innerHTML = ""
  }

  // 背景への click 伝播を止める
  stop(event) {
    event.stopPropagation()
  }
}
