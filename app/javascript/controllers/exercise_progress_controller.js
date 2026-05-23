import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["achieved", "deltaWrap", "deltaValue"]
  static values = { previousDifficulty: String }

  connect() {
    this.groupRow = this.element.closest(".planned-group-row")
    this.boundUpdate = () => this.update()
    this.bindInputs()
    this.update()
  }

  disconnect() {
    this.inputs?.forEach((input) => input.removeEventListener("input", this.boundUpdate))
  }

  bindInputs() {
    if (!this.groupRow) return

    this.inputs = this.groupRow.querySelectorAll("input[name='execution[actual_weight]'], input[name='execution[actual_reps]']")
    this.inputs.forEach((input) => input.addEventListener("input", this.boundUpdate))
  }

  update() {
    if (!this.groupRow || !this.hasAchievedTarget) return

    const achieved = this.achievedDifficulty()
    if (achieved === null) return

    this.achievedTarget.textContent = this.format(achieved)

    if (!this.hasDeltaWrapTarget || !this.hasDeltaValueTarget) return

    const previous = Number(this.previousDifficultyValue)
    if (!Number.isFinite(previous) || previous === 0) return

    const deltaPercent = ((achieved - previous) / previous) * 100
    this.deltaValueTarget.textContent = `${deltaPercent >= 0 ? "+" : ""}${this.format(deltaPercent)}%`
  }

  achievedDifficulty() {
    const forms = this.groupRow.querySelectorAll("form.actual-set-form")
    if (forms.length === 0) return null

    return Array.from(forms).reduce((total, form) => {
      const reps = Number(form.querySelector("input[name='execution[actual_reps]']")?.value)
      const weight = Number(form.querySelector("input[name='execution[actual_weight]']")?.value)

      if (!Number.isFinite(reps) || !Number.isFinite(weight) || reps <= 0 || weight < 0) return total

      return total + (weight * reps * this.intensityFactor(reps))
    }, 0)
  }

  intensityFactor(reps) {
    const factor = 1.35 - (0.04 * (Math.round(reps) - 1))
    return Math.max(0.6, Math.min(1.35, factor))
  }

  format(value) {
    const rounded = Math.round(value * 10) / 10
    return Number.isInteger(rounded) ? `${rounded}` : rounded.toFixed(1)
  }
}
