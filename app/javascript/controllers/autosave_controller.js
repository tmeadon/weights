import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { delay: { type: Number, default: 200 } }

  queue() {
    clearTimeout(this.timeout)
    this.timeout = setTimeout(() => {
      this.submitNow()
    }, this.delayValue)
  }

  submit() {
    clearTimeout(this.timeout)
    this.submitNow()
  }

  submitNow() {
    if (this.element.requestSubmit) {
      this.element.requestSubmit()
    } else {
      this.element.submit()
    }
  }

  disconnect() {
    clearTimeout(this.timeout)
  }
}
