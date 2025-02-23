every 1.day, at: "04:00 am" do
  runner "Site.cycle_stale_salts!"
end
