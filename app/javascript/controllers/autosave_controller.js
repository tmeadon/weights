import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { delay: { type: Number, default: 200 } }
  static targets = ["status"]

  connect() {
    this.hideStatus()
  }

  queue() {
    clearTimeout(this.timeout)
    this.showStatus("Saving...", "saving")
    this.timeout = setTimeout(() => {
      this.submitNow()
    }, this.delayValue)
  }

  submit() {
    clearTimeout(this.timeout)
    this.submitNow()
  }

  retry() {
    if (this.submitting) return

    this.submitNow()
  }

  async submitNow() {
    clearTimeout(this.timeout)

    if (this.submitting) {
      this.needsResubmit = true
      return
    }

    this.submitting = true
    this.needsResubmit = false
    const requestSignature = this.formSignature()

    this.showStatus("Saving...", "saving")

    try {
      const response = await fetch(this.element.action, {
        method: this.element.method,
        credentials: "same-origin",
        headers: {
          Accept: "text/vnd.turbo-stream.html"
        },
        body: new FormData(this.element)
      })

      const html = await response.text()
      if (html.trim().length > 0 && window.Turbo?.renderStreamMessage) {
        window.Turbo.renderStreamMessage(html)
      }

      if (response.ok) {
        if (requestSignature === this.formSignature()) {
          this.showStatus("Saved", "saved")
        } else {
          this.needsResubmit = true
          this.showStatus("Saving...", "saving")
        }
      } else {
        this.showStatus("Retry save", "error")
      }
    } catch (_error) {
      this.showStatus("Retry save", "error")
    } finally {
      this.submitting = false

      if (this.needsResubmit) {
        this.submitNow()
      }
    }
  }

  disconnect() {
    clearTimeout(this.timeout)
    clearTimeout(this.statusTimeout)
  }

  formSignature() {
    return JSON.stringify(Object.fromEntries(new FormData(this.element).entries()))
  }

  hideStatus() {
    if (!this.hasStatusTarget) return

    this.statusTarget.hidden = true
    this.statusTarget.disabled = true
    this.statusTarget.dataset.state = "idle"
    this.statusTarget.textContent = ""
  }

  showStatus(label, state) {
    if (!this.hasStatusTarget) return

    clearTimeout(this.statusTimeout)
    this.statusTarget.hidden = false
    this.statusTarget.disabled = state !== "error"
    this.statusTarget.dataset.state = state
    this.statusTarget.textContent = label

    if (state === "saved") {
      this.statusTimeout = setTimeout(() => {
        this.hideStatus()
      }, 1500)
    }
  }
}
