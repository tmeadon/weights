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

  prefillFromAbove() {
    const previousForm = this.previousSetForm()
    if (!previousForm) return

    const currentWeightInput = this.element.querySelector("input[name='execution[actual_weight]']")
    const currentRepsInput = this.element.querySelector("input[name='execution[actual_reps]']")
    const previousWeightInput = previousForm.querySelector("input[name='execution[actual_weight]']")
    const previousRepsInput = previousForm.querySelector("input[name='execution[actual_reps]']")

    if (!currentWeightInput || !currentRepsInput || !previousWeightInput || !previousRepsInput) return
    if (this.valuePresent(currentWeightInput.value) || this.valuePresent(currentRepsInput.value)) return
    if (this.valueBlank(previousWeightInput.value) && this.valueBlank(previousRepsInput.value)) return

    currentWeightInput.value = previousWeightInput.value
    currentRepsInput.value = previousRepsInput.value
    this.queue()
  }

  valuePresent(value) {
    return value !== null && value !== undefined && value !== ""
  }

  valueBlank(value) {
    return !this.valuePresent(value)
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

  previousSetForm() {
    const currentRow = this.element.closest(".planned-set-row")
    if (!currentRow) return null

    let previousRow = currentRow.previousElementSibling

    while (previousRow) {
      const previousForm = previousRow.querySelector("form.actual-set-form")
      if (previousForm) return previousForm

      previousRow = previousRow.previousElementSibling
    }

    return null
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
