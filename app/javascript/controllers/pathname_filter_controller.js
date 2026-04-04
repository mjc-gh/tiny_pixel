import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["pageViewsFrame", "visitorsFrame", "performanceFrame", "filterIndicator"]
  static values = { pathname: String, site: String, interval: String }

  selectPathname(event) {
    const pathname = event.currentTarget.dataset.pathname
    this.pathnamValue = pathname

    this.updateFrameSources(pathname)
    this.showFilterIndicator(pathname)
  }

  clearFilter() {
    this.pathnamValue = ""

    this.updateFrameSources(null)
    this.hideFilterIndicator()
  }

  updateFrameSources(pathname) {
    const baseParams = `interval=${this.intervalValue}`
    const pathnameParam = pathname ? `&pathname=${encodeURIComponent(pathname)}` : ""

    if (this.hasPageViewsFrameTarget) {
      const pageViewsUrl = this.pageViewsFrameTarget.src.split("?")[0]
      this.pageViewsFrameTarget.src = `${pageViewsUrl}?${baseParams}${pathnameParam}`
    }

    if (this.hasVisitorsFrameTarget) {
      const visitorsUrl = this.visitorsFrameTarget.src.split("?")[0]
      this.visitorsFrameTarget.src = `${visitorsUrl}?${baseParams}${pathnameParam}`
    }

    if (this.hasPerformanceFrameTarget) {
      const performanceUrl = this.performanceFrameTarget.src.split("?")[0]
      this.performanceFrameTarget.src = `${performanceUrl}?${baseParams}${pathnameParam}`
    }
  }

  showFilterIndicator(pathname) {
    if (this.hasFilterIndicatorTarget) {
      this.filterIndicatorTarget.classList.remove("hidden")
      const pathnameText = this.filterIndicatorTarget.querySelector("[data-pathname-text]")
      if (pathnameText) {
        pathnameText.textContent = pathname
      }
    }
  }

  hideFilterIndicator() {
    if (this.hasFilterIndicatorTarget) {
      this.filterIndicatorTarget.classList.add("hidden")
    }
  }
}
