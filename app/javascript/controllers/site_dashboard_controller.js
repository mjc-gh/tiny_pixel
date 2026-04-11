import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["pageViewsFrame", "visitorsFrame", "avgDurationFrame", "bounceRateFrame", "filterIndicator", "startDate", "endDate", "pathnamesFrame", "countriesFrame", "browsersFrame", "devicesFrame", "referrersFrame"]
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

  buildParams(pathname, hostname) {
    const params = new URLSearchParams()
    params.set("interval", this.intervalValue)
    if (pathname) params.set("pathname", pathname)
    if (hostname) params.set("hostname", hostname)
    if (this.startDateValue) params.set("start_date", this.startDateValue)
    if (this.endDateValue) params.set("end_date", this.endDateValue)
    return params
  }

  updateFrameSource(target, params) {
    if (target) {
      const baseUrl = target.src.split("?")[0]
      target.src = `${baseUrl}?${params.toString()}`
    }
  }

  updateFrameSources(pathname, hostname) {
    const params = this.buildParams(pathname, hostname)

    if (this.hasPageViewsFrameTarget) {
      this.updateFrameSource(this.pageViewsFrameTarget, params)
    }

    if (this.hasVisitorsFrameTarget) {
      this.updateFrameSource(this.visitorsFrameTarget, params)
    }

    if (this.hasAvgDurationFrameTarget) {
      this.updateFrameSource(this.avgDurationFrameTarget, params)
    }

    if (this.hasBounceRateFrameTarget) {
      this.updateFrameSource(this.bounceRateFrameTarget, params)
    }

    if (this.hasPathnamesFrameTarget) {
      this.updateFrameSource(this.pathnamesFrameTarget, params)
    }

    if (this.hasCountriesFrameTarget) {
      const countryParams = new URLSearchParams(params)
      countryParams.set("dimension_type", "country")
      this.updateFrameSource(this.countriesFrameTarget, countryParams)
    }

    if (this.hasBrowsersFrameTarget) {
      const browserParams = new URLSearchParams(params)
      browserParams.set("dimension_type", "browser")
      this.updateFrameSource(this.browsersFrameTarget, browserParams)
    }

    if (this.hasDevicesFrameTarget) {
      const deviceParams = new URLSearchParams(params)
      deviceParams.set("dimension_type", "device_type")
      this.updateFrameSource(this.devicesFrameTarget, deviceParams)
    }

    if (this.hasReferrersFrameTarget) {
      const referrerParams = new URLSearchParams(params)
      referrerParams.set("dimension_type", "referrer_hostname")
      this.updateFrameSource(this.referrersFrameTarget, referrerParams)
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
