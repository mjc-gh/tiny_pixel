import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["source", "button"]

  copy() {
    const text = this.sourceTarget.textContent.trim()
    navigator.clipboard.writeText(text).then(() => {
      this.showSuccess()
    }).catch(() => {
      console.error("Failed to copy to clipboard")
    })
  }

  showSuccess() {
    const originalText = this.buttonTarget.textContent
    this.buttonTarget.textContent = this.buttonTarget.dataset.copiedText || "Copied!"
    
    setTimeout(() => {
      this.buttonTarget.textContent = originalText
    }, 2000)
  }
}
