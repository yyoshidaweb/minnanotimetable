import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    // input と候補表示領域（results）をターゲットとして使用
    static targets = ["input", "results"]

    // コントローラ読み込み時に渡される URL を保持（search 用）
    static values = { url: String }

    connect() {
        // フォーカス時：入力済みなら自動的に再検索して候補を再表示
        this.inputTarget.addEventListener("focus", () => {
            if (this.inputTarget.value.trim() !== "") {
                this.search({ target: this.inputTarget })
            }
        })

        // フォーカスが外れた時：候補が一瞬で消えないよう少し遅らせてからクリア
        this.inputTarget.addEventListener("blur", () => {
            setTimeout(() => this.resultsTarget.innerHTML = "", 100)
        })

        // 候補をクリックする瞬間に blur が発火する問題を防ぐための処理
        this.resultsTarget.addEventListener("mousedown", (e) => {
            e.preventDefault() // blur を防止 → 候補クリックを正常動作させる
        })
    }

    search(event) {
        // 現在の入力値を取得
        const query = event.target.value

        // 空文字なら候補を消して終了
        if (query.length === 0) {
            this.resultsTarget.innerHTML = ""
            return
        }

        // サーバーへ検索リクエスト（Turbo Stream を受け取る）
        fetch(`${this.urlValue}?query=${encodeURIComponent(query)}`, {
            headers: { Accept: "text/vnd.turbo-stream.html" } // Turbo Stream の MIME タイプ
        })
            .then(r => r.text()) // レスポンスをテキストとして受け取る
            .then(html => {
                // 受け取った部分テンプレート（候補一覧）を results に描画
                this.resultsTarget.innerHTML = html
            })
    }

    choose(event) {
        // data-tag-suggestion-name-value に入っている候補名を取得
        const name = event.target.dataset.tagSuggestionNameValue

        // 入力欄へ選択した名称を挿入
        this.inputTarget.value = name

        // 候補一覧を消す
        this.resultsTarget.innerHTML = ""
    }
}
