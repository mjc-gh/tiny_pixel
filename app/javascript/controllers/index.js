// Import and register all your controllers from the importmap via controllers/**/*_controller
import { application } from "controllers/application"
import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading"
import { Slideover } from "tailwindcss-stimulus-components"

eagerLoadControllersFrom("controllers", application)

application.register("slideover", Slideover)
