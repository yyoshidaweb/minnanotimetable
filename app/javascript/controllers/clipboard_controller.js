import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static values = { text: String }
    static targets = ["toast"]

    copy() {
        navigator.clipboard.writeText(this.textValue).then(() => {
            this.showToast()
        })
    }

    showToast() {
        const toast = this.toastTarget
        toast.classList.remove("opacity-0")
        toast.classList.add("opacity-100")

        // 2秒後にフェードアウト
        setTimeout(() => {
            toast.classList.remove("opacity-100")
            toast.classList.add("opacity-0")
        }, 2000)
    }
}