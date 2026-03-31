import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["lightIcon", "darkIcon"]

  connect() {
    this.updateIcons()
  }

  toggle() {
    const isDark = document.documentElement.classList.toggle("dark")
    localStorage.setItem("theme", isDark ? "dark" : "light")
    this.updateIcons()
  }

  updateIcons() {
    const isDark = document.documentElement.classList.contains("dark")
    this.lightIconTarget.classList.toggle("hidden", !isDark)
    this.darkIconTarget.classList.toggle("hidden", isDark)
  }
}
