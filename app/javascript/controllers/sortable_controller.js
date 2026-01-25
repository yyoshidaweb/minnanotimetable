import { Controller } from "@hotwired/stimulus"
import Sortable from "sortablejs"

// ステージ一覧をドラッグ&ドロップで並び替える
export default class extends Controller {
    connect() {
        this.sortable = Sortable.create(this.element, {
            animation: 150, // 並び替え時のアニメーション
        })
    }
}