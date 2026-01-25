import { Controller } from "@hotwired/stimulus"
import Sortable from "sortablejs"

// ステージ一覧をドラッグ&ドロップで並び替える
export default class extends Controller {
    connect() {
        this.sortable = Sortable.create(this.element, {
            animation: 150, // 並び替え時のアニメーション
            handle: ".stage-handle", // ドラッグ可能な部分を指定
            scroll: true,              // 自動スクロール有効
            scrollSensitivity: 120,     // 端から何pxで反応するか
            scrollSpeed: 10,           // スクロール速度
            scrollContainer: this.element, // スクロールさせるコンテナ
            forceFallback: true,        // フォールバックモードを強制的に有効化
        })
    }
}