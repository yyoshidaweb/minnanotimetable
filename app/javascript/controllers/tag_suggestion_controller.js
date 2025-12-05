import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["input", "results"]
    static values = { url: String }

    // 入力時に検索
    search(event) {
        const query = event.target.value
        if (query.length === 0) {
            this.resultsTarget.innerHTML = ""
            return
        }

        fetch(`${this.urlValue}?query=${encodeURIComponent(query)}`, {
            headers: { Accept: "text/vnd.turbo-stream.html" }
        }).then(r => r.text()).then(html => {
            this.resultsTarget.innerHTML = html
        })
    }

    // 候補を選択
    choose(event) {
        const name = event.target.dataset.tagSuggestionNameValue
        this.inputTarget.value = name
        this.resultsTarget.innerHTML = ""
    }
}
