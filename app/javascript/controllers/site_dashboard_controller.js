import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["startDate", "endDate"]
  static values = {
    pathname: String,
    hostname: String,
    site: String,
    interval: String,
    startDate: String,
    endDate: String,
    dimensionType: String,
    dimensionValue: String
  }

  selectPathname(event) {
    this.pathnameValue = event.currentTarget.dataset.pathname
    this.hostnameValue = event.currentTarget.dataset.hostname || ""
    this.visit()
  }

  selectDimension(event) {
    this.dimensionTypeValue = event.currentTarget.dataset.dimensionType
    this.dimensionValueValue = event.currentTarget.dataset.dimensionValue
    this.visit()
  }

  clearPathnameFilter() {
    this.pathnameValue = ""
    this.hostnameValue = ""
    this.visit()
  }

  clearDimensionFilter() {
    this.dimensionTypeValue = ""
    this.dimensionValueValue = ""
    this.visit()
  }

  updateDateRange() {
    this.startDateValue = this.hasStartDateTarget ? this.startDateTarget.value : ""
    this.endDateValue = this.hasEndDateTarget ? this.endDateTarget.value : ""
    this.visit()
  }

  visit() {
    const params = new URLSearchParams()

    params.set("interval", this.intervalValue)

    if (this.pathnameValue) params.set("pathname", this.pathnameValue)
    if (this.hostnameValue) params.set("hostname", this.hostnameValue)
    if (this.startDateValue) params.set("start_date", this.startDateValue)
    if (this.endDateValue) params.set("end_date", this.endDateValue)
    if (this.dimensionTypeValue) params.set("dimension_type", this.dimensionTypeValue)
    if (this.dimensionValueValue) params.set("dimension_value", this.dimensionValueValue)

    const baseURL = window.location.pathname
    const newURL = params.toString() ? `${baseURL}?${params.toString()}` : baseURL

    Turbo.visit(newURL, { action: "advance" })
  }
}
