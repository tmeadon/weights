import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["panel", "repsInput", "select", "weightInput"]
  static values = { url: String }

  connect() {
    this.load()
  }

  async load() {
    const exerciseId = this.selectTarget.value

    if (!exerciseId) {
      this.panelTarget.innerHTML = "<p class=\"exercise-history-empty\">Pick an exercise to see recent logged sets.</p>"
      return
    }

    this.panelTarget.innerHTML = "<p class=\"exercise-history-empty\">Loading recent history...</p>"

    this.abortController?.abort()
    this.abortController = new AbortController()

    try {
      const response = await fetch(`${this.urlValue}?exercise_id=${encodeURIComponent(exerciseId)}`, {
        headers: { Accept: "text/html" },
        signal: this.abortController.signal,
        credentials: "same-origin"
      })

      if (!response.ok) throw new Error("Request failed")

      this.panelTarget.innerHTML = await response.text()
    } catch (error) {
      if (error.name === "AbortError") return

      this.panelTarget.innerHTML = "<p class=\"exercise-history-empty\">Recent history is unavailable right now.</p>"
    }
  }

  reuse(event) {
    const { reps, weight } = event.currentTarget.dataset

    if (this.hasRepsInputTarget && reps) {
      this.repsInputTarget.value = reps
      this.repsInputTarget.dispatchEvent(new Event("input", { bubbles: true }))
    }

    if (this.hasWeightInputTarget) {
      this.weightInputTarget.value = weight || ""
      this.weightInputTarget.dispatchEvent(new Event("input", { bubbles: true }))
    }
  }

  disconnect() {
    this.abortController?.abort()
  }
}
