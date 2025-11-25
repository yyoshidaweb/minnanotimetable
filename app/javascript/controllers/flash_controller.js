import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="flash"
export default class extends Controller {
  connect() {
    setTimeout(() => {
      this.element.remove();
    }, 3000); // 3秒後に削除
  }
}
