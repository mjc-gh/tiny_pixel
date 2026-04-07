import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["pageViewsFrame", "visitorsFrame", "avgDurationFrame", "bounceRateFrame", "filterIndicator"]
  static values = { pathname: String, hostname: String, site: String, interval: String }

  selectPathname(event) {
    const pathname = event.currentTarget.dataset.pathname
    const hostname = event.currentTarget.dataset.hostname
    this.pathnameValue = pathname
    this.hostnameValue = hostname

    this.updateFrameSources(pathname, hostname)
    this.showFilterIndicator(pathname, hostname)
  }

  clearFilter() {
    this.pathnameValue = ""
    this.hostnameValue = ""

    this.updateFrameSources(null, null)
    this.hideFilterIndicator()
  }

  updateFrameSources(pathname, hostname) {
    const baseParams = `interval=${this.intervalValue}`
    const pathnameParam = pathname ? `&pathname=${encodeURIComponent(pathname)}` : ""
    const hostnameParam = hostname ? `&hostname=${encodeURIComponent(hostname)}` : ""

    if (this.hasPageViewsFrameTarget) {
      const pageViewsUrl = this.pageViewsFrameTarget.src.split("?")[0]
      this.pageViewsFrameTarget.src = `${pageViewsUrl}?${baseParams}${pathnameParam}${hostnameParam}`
    }

    if (this.hasVisitorsFrameTarget) {
      const visitorsUrl = this.visitorsFrameTarget.src.split("?")[0]
      this.visitorsFrameTarget.src = `${visitorsUrl}?${baseParams}${pathnameParam}${hostnameParam}`
    }

    if (this.hasAvgDurationFrameTarget) {
      const avgDurationUrl = this.avgDurationFrameTarget.src.split("?")[0]
      this.avgDurationFrameTarget.src = `${avgDurationUrl}?${baseParams}${pathnameParam}${hostnameParam}`
    }

    if (this.hasBounceRateFrameTarget) {
      const bounceRateUrl = this.bounceRateFrameTarget.src.split("?")[0]
      this.bounceRateFrameTarget.src = `${bounceRateUrl}?${baseParams}${pathnameParam}${hostnameParam}`
    }
  }

  showFilterIndicator(pathname, hostname) {
    if (this.hasFilterIndicatorTarget) {
      this.filterIndicatorTarget.classList.remove("hidden")
      const filterText = this.filterIndicatorTarget.querySelector("[data-filter-text]")
      if (filterText) {
        let displayText = pathname
        if (hostname) {
          displayText = `${hostname}${pathname}`
        }
        filterText.textContent = displayText
      }
    }
  }

  hideFilterIndicator() {
    if (this.hasFilterIndicatorTarget) {
      this.filterIndicatorTarget.classList.add("hidden")
    }
  }
}
