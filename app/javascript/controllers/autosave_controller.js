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

  async submitNow() {
    if (this.submitting) return
    this.submitting = true

    try {
      const response = await fetch(this.element.action, {
        method: this.element.method,
        credentials: "same-origin",
        headers: {
          Accept: "text/vnd.turbo-stream.html"
        },
        body: new FormData(this.element)
      })

      if (!response.ok) return

      const html = await response.text()
      if (html.trim().length > 0 && window.Turbo?.renderStreamMessage) {
        window.Turbo.renderStreamMessage(html)
      }
    } finally {
      this.submitting = false
    }
  }

  disconnect() {
    clearTimeout(this.timeout)
  }
}
