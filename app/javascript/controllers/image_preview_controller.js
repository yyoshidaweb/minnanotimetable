import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["preview", "dropzone", "label"]

  // 通常選択
  preview(event) {
    const file = event.target.files[0]
    this.showPreview(file)
    this.updateLabel(file)
  }

  // ドラッグ中に重なった時
  dragOver(event) {
    // ブラウザがファイルを開くのを防止
    event.preventDefault()
    this.dropzoneTarget.classList.add("bg-gray-100")
  }

  // ドラッグ中に重なっていない時
  dragLeave() {
    this.dropzoneTarget.classList.remove("bg-gray-100")
  }

  // ドロップ時
  drop(event) {
    event.preventDefault()
    const file = event.dataTransfer.files[0]
    const allowedTypes = ["image/png", "image/jpeg"]
    if (!file || !allowedTypes.includes(file.type)) {
      alert("画像ファイルのみドロップできます")
      return
    }
    const input = this.element.querySelector("input[type='file']")
    // フォーム送信のためにinputにドロップしたファイルをセット
    input.files = event.dataTransfer.files
    this.showPreview(file)
    this.updateLabel(file)
    this.dropzoneTarget.classList.remove("bg-gray-100")
  }

  // プレビュー共通処理
  showPreview(file) {
    const allowedTypes = ["image/png", "image/jpeg"]
    // 画像以外は無視
    if (!allowedTypes.includes(file.type)) {
      alert("画像ファイルのみ選択できます")
      return
    }
    const reader = new FileReader()
    reader.onload = (e) => {
      this.previewTarget.src = e.target.result
      this.previewTarget.classList.remove("hidden")
    }
    // プレビュー画像を表示
    reader.readAsDataURL(file)
  }

  // 画像選択中はラベルを更新
  updateLabel(file) {
    if (!file) return
    this.labelTarget.textContent = `選択中: ${file.name}`
  }
}