every :hour do
  runner "Site.perform_periodic_operations"
end
