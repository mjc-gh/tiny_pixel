import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["pageViewsFrame", "visitorsFrame", "avgDurationFrame", "bounceRateFrame", "filterIndicator", "startDate", "endDate", "pathnamesFrame"]
  static values = { pathname: String, hostname: String, site: String, interval: String, startDate: String, endDate: String }

  selectPathname(event) {
    const pathname = event.currentTarget.dataset.pathname
    const hostname = event.currentTarget.dataset.hostname
    this.pathnameValue = pathname
    this.hostnameValue = hostname

    this.updateFrameSources(pathname, hostname)
    this.showFilterIndicator(pathname, hostname)
    this.updateBrowserURL(pathname, hostname)
  }

  clearFilter() {
    this.pathnameValue = ""
    this.hostnameValue = ""

    this.updateFrameSources(null, null)
    this.hideFilterIndicator()
    this.updateBrowserURL(null, null)
  }

  updateDateRange() {
    const startDate = this.hasStartDateTarget ? this.startDateTarget.value : null
    const endDate = this.hasEndDateTarget ? this.endDateTarget.value : null

    this.startDateValue = startDate || ""
    this.endDateValue = endDate || ""

    this.updateAllFrameSources()
    this.updateBrowserURLWithDates()
  }

  updateAllFrameSources() {
    this.updateFrameSources(this.pathnameValue || null, this.hostnameValue || null)
  }

  updateFrameSources(pathname, hostname) {
    const baseParams = `interval=${this.intervalValue}`
    const pathnameParam = pathname ? `&pathname=${encodeURIComponent(pathname)}` : ""
    const hostnameParam = hostname ? `&hostname=${encodeURIComponent(hostname)}` : ""
    const startDateParam = this.startDateValue ? `&start_date=${this.startDateValue}` : ""
    const endDateParam = this.endDateValue ? `&end_date=${this.endDateValue}` : ""

    const allParams = `${baseParams}${pathnameParam}${hostnameParam}${startDateParam}${endDateParam}`

    if (this.hasPageViewsFrameTarget) {
      const pageViewsUrl = this.pageViewsFrameTarget.src.split("?")[0]
      this.pageViewsFrameTarget.src = `${pageViewsUrl}?${allParams}`
    }

    if (this.hasVisitorsFrameTarget) {
      const visitorsUrl = this.visitorsFrameTarget.src.split("?")[0]
      this.visitorsFrameTarget.src = `${visitorsUrl}?${allParams}`
    }

    if (this.hasAvgDurationFrameTarget) {
      const avgDurationUrl = this.avgDurationFrameTarget.src.split("?")[0]
      this.avgDurationFrameTarget.src = `${avgDurationUrl}?${allParams}`
    }

    if (this.hasBounceRateFrameTarget) {
      const bounceRateUrl = this.bounceRateFrameTarget.src.split("?")[0]
      this.bounceRateFrameTarget.src = `${bounceRateUrl}?${allParams}`
    }

    if (this.hasPathnamesFrameTarget) {
      const pathnamesUrl = this.pathnamesFrameTarget.src.split("?")[0]
      this.pathnamesFrameTarget.src = `${pathnamesUrl}?${allParams}`
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

  updateBrowserURLWithDates() {
    // Build URL with all filter params including dates
    const baseURL = window.location.pathname
    const params = new URLSearchParams(window.location.search)
    
    // Update date parameters
    if (this.startDateValue) {
      params.set("start_date", this.startDateValue)
    } else {
      params.delete("start_date")
    }
    
    if (this.endDateValue) {
      params.set("end_date", this.endDateValue)
    } else {
      params.delete("end_date")
    }
    
    // Ensure interval is preserved
    if (!params.has("interval")) {
      params.set("interval", this.intervalValue)
    }
    
    const newURL = params.toString() ? `${baseURL}?${params.toString()}` : baseURL
    
    // Use Turbo.visit with advance action to update browser URL
    Turbo.visit(newURL, { action: "advance" })
  }

  updateBrowserURL(pathname, hostname) {
    // Build URL with filter params
    const baseURL = window.location.pathname
    const params = new URLSearchParams(window.location.search)
    
    // Update or remove filter parameters
    if (pathname) {
      params.set("pathname", pathname)
    } else {
      params.delete("pathname")
    }
    
    if (hostname) {
      params.set("hostname", hostname)
    } else {
      params.delete("hostname")
    }
    
    // Preserve date params if they exist
    if (this.startDateValue) {
      params.set("start_date", this.startDateValue)
    }
    if (this.endDateValue) {
      params.set("end_date", this.endDateValue)
    }
    
    // Ensure interval is preserved
    if (!params.has("interval")) {
      params.set("interval", this.intervalValue)
    }
    
    const newURL = params.toString() ? `${baseURL}?${params.toString()}` : baseURL
    
    // Use Turbo.visit with advance action to update browser URL
    Turbo.visit(newURL, { action: "advance" })
  }
}

