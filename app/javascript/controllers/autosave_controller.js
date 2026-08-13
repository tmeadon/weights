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
    currentWeightInput.dispatchEvent(new Event("input", { bubbles: true }))
    currentRepsInput.dispatchEvent(new Event("input", { bubbles: true }))
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
          Accept: "application/json"
        },
        body: new FormData(this.element)
      })

      if (response.headers.get("content-type")?.includes("application/json")) {
        const payload = await response.json()
        this.applySaveResult(payload)
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

  applySaveResult(payload) {
    if (!payload?.workout?.workout_sets) return

    const groupRow = this.element.closest(".planned-group-row")
    if (!groupRow) return

    const exerciseId = Number(this.element.querySelector("select[name='execution[exercise_id]']")?.value)
    if (!Number.isFinite(exerciseId)) return

    const exerciseSets = payload.workout.workout_sets.filter((workoutSet) => Number(workoutSet.exercise_id) === exerciseId)
    const pbSets = exerciseSets.filter((workoutSet) => workoutSet.personal_best)

    const summary = groupRow.querySelector(".exercise-pb-summary")
    const badge = groupRow.querySelector(".personal-best-badge")
    const text = groupRow.querySelector(".exercise-pb-summary-text")

    if (!summary || !badge || !text) return

    const latestPb = pbSets.sort((a, b) => (a.position - b.position) || ((a.created_at || "").localeCompare(b.created_at || ""))).at(-1)
    const visible = Boolean(latestPb)

    summary.classList.toggle("exercise-pb-summary-visible", visible)
    badge.textContent = visible ? "🏆" : ""
    text.textContent = visible
      ? (latestPb.personal_best_previous_label
        ? `Previous PB: ${latestPb.personal_best_previous_label}`
        : "New PB")
      : ""
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
      }, 700)
    }
  }
}
