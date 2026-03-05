import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["icon"]
    copy() {
        navigator.clipboard.writeText(this.textValue).then(() => {
            // アイコン要素を取得
            const icon = this.iconTarget
            // コピーアイコンをチェックマークに変更
            icon.textContent = "check"
            // 2秒後に元のコピーアイコンに戻す
            setTimeout(() => icon.textContent = "content_copy", 2000)
        })
    }
}