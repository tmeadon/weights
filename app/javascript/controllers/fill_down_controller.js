import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["row"]

  fillDown() {
    const rows = this.rowTargets.filter((row) => row.querySelector("form.actual-set-form"))
    if (rows.length === 0) return

    const firstForm = rows[0].querySelector("form.actual-set-form")
    if (!firstForm) return

    const firstWeightInput = this.inputFor(firstForm, "execution[actual_weight]")
    const firstRepsInput = this.inputFor(firstForm, "execution[actual_reps]")
    if (!firstWeightInput || !firstRepsInput) return

    let templateWeight = firstWeightInput.value
    let templateReps = firstRepsInput.value

    if (this.blank(templateWeight) && this.blank(templateReps)) {
      templateWeight = rows[0].dataset.targetWeight || ""
      templateReps = rows[0].dataset.targetReps || ""
    }

    if (this.blank(templateWeight) && this.blank(templateReps)) return

    rows.forEach((row) => {
      const form = row.querySelector("form.actual-set-form")
      if (!form) return

      const weightInput = this.inputFor(form, "execution[actual_weight]")
      const repsInput = this.inputFor(form, "execution[actual_reps]")
      if (!weightInput || !repsInput) return

      let changed = false

      if (this.blank(weightInput.value) && this.present(templateWeight)) {
        weightInput.value = templateWeight
        changed = true
      }

      if (this.blank(repsInput.value) && this.present(templateReps)) {
        repsInput.value = templateReps
        changed = true
      }

      if (changed) {
        form.dataset.prefilledFromAbove = "true"
        this.dispatchInput(weightInput)
        this.dispatchInput(repsInput)
      }
    })
  }

  inputFor(form, name) {
    return form.querySelector(`input[name='${name}']`)
  }

  dispatchInput(element) {
    element.dispatchEvent(new Event("input", { bubbles: true }))
  }

  present(value) {
    return value !== null && value !== undefined && value !== ""
  }

  blank(value) {
    return !this.present(value)
  }
}
