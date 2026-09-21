import { Controller } from "@hotwired/stimulus"

// セカンドヘッダーで、戻り先ラベルが収まるときだけ表示する。
// ページタイトルが長くてスペース不足のときは「…」省略せず非表示にする。
// Connects to data-controller="secondary-header"
export default class extends Controller {
  static targets = [ "back", "label" ]

  connect() {
    this.adjustLabel = this.adjustLabel.bind(this)
    this.adjustLabel()
    // ヘッダー幅の変化だけ監視する（ラベルの出し分けではヘッダーサイズが変わらないのでループしない）
    this.resizeObserver = new ResizeObserver(this.adjustLabel)
    this.resizeObserver.observe(this.element)
    if (document.fonts?.ready) {
      document.fonts.ready.then(this.adjustLabel)
    }
  }

  disconnect() {
    this.resizeObserver?.disconnect()
  }

  adjustLabel() {
    if (!this.hasLabelTarget || !this.hasBackTarget) return

    this.labelTarget.classList.remove("hidden")
    const overflows = this.backTarget.scrollWidth > this.backTarget.clientWidth
    this.labelTarget.classList.toggle("hidden", overflows)
  }
}
