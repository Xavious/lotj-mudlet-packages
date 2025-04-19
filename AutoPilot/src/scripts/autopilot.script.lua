if not autopilot and io.exists(getMudletHomeDir().."/AutoPilot.lua") then
  table.load(getMudletHomeDir().."/AutoPilot.lua", autopilot)
  cecho("\n[<cyan>AutoPilot<reset>] Loaded save file.<reset>\n")
end
autopilot = autopilot or {}
autopilot.alias = {}
autopilot.trigger = {}
autopilot.ships = autopilot.ships or {}
autopilot.ship = autopilot.ship or {}
autopilot.routes = autopilot.routes or {}
autopilot.runningCargo = autopilot.runningCargo or false

function autopilot.tableString(s)
  local t = {}
  for item in string.gmatch(s, '([^,]+)') do
    local trimmed = item:match("^%s*(.-)%s*$")
    table.insert(t, trimmed)
  end
  return t
end

function autopilot.alias.profit()
  local now = getEpoch()
  local elapsed = now - autopilot.startTime
  
  -- Convert start time to a formatted local string
  local startTimeStr = os.date("%c", autopilot.startTime)
  
  -- Calculate elapsed hours and minutes
  local hours = math.floor(elapsed / 3600)
  local minutes = math.floor((elapsed % 3600) / 60)
  
  autopilot.profit = autopilot.revenue - autopilot.expense - autopilot.fuelCost
  local perHour = (autopilot.profit / elapsed) * 3600
  
  cecho("<white>---------------------------------------------\n")
  cecho("<yellow>Cargo Session Financial Report\n")
  cecho("<white>---------------------------------------------\n")
  cecho("<cyan>Time Started    : <reset>" .. startTimeStr .. "\n")
  cecho("<cyan>Elapsed Time    : <reset>" .. hours .. "h " .. minutes .. "m\n")
  cecho("<cyan>Expense         : <reset>" .. autopilot.expense .. "\n")
  cecho("<cyan>Revenue         : <reset>" .. autopilot.revenue .. "\n")
  cecho("<cyan>Fuel Cost       : <reset>" .. autopilot.fuelCost .. "\n")
  cecho("<cyan>Profit          : <reset>" .. autopilot.profit .. "\n")
  cecho("<cyan>Credits/Hour    : <reset>" .. string.format("%.2f", perHour) .. "\n")
  cecho("<white>---------------------------------------------<reset>\n")
end


function autopilot.alias.help()
  cecho("<white>------------------------------------------------------------\n")
  cecho("<cyan>                       AutoPilot Help<reset>\n")
  cecho("<white>------------------------------------------------------------\n\n")
  
  -- General Flight Commands
  cecho("<cyan>GENERAL FLIGHT COMMANDS<reset>\n")
  cecho("<white>------------------------------------------------------------\n")
  cecho("<yellow>ap status<reset>\n")
  cecho("   Displays current ship attributes, waypoints, and cargo route information.\n\n")
  cecho("<yellow>ap fly <planet/planets><reset>\n")
  cecho("   Initiates flight to the target destination. Use commas to separate multiple planets.\n\n")
  cecho("<yellow>ap on<reset>\n")
  cecho("   Enables autopilot triggers (flight and cargo mode).\n\n")
  cecho("<yellow>ap off<reset>\n")
  cecho("   Disables autopilot triggers.\n\n")
  cecho("<yellow>ap clear<reset>\n")
  cecho("   Clears all autopilot attributes (ship, route, waypoints, destination).\n\n")
  
  -- Ship Attribute Setup
  cecho("<cyan>SHIP ATTRIBUTE COMMANDS<reset>\n")
  cecho("<white>------------------------------------------------------------\n")
  cecho("<yellow>ap set name <name><reset>\n")
  cecho("   Sets your ship's name (used for open/launch commands).\n\n")
  cecho("<yellow>ap set enter <commands><reset>\n")
  cecho("   Configures the (comma separated) commands to execute upon entering.\n\n")
  cecho("<yellow>ap set exit <commands><reset>\n")
  cecho("   Configures the (comma separated) commands to execute upon landing.\n\n")
  cecho("<yellow>ap set hatch <code><reset>\n")
  cecho("   Sets the hatch code for your ship.\n\n")
  cecho("<yellow>ap set capacity <amount><reset>\n")
  cecho("   Sets your ship's cargo capacity for cargo hauling.\n\n")
  
  -- Ship Management Commands
  cecho("<cyan>SHIP MANAGEMENT COMMANDS<reset>\n")
  cecho("<white>------------------------------------------------------------\n")
  cecho("<yellow>ap save ship<reset>\n")
  cecho("   Saves the current ship to your ship list.\n\n")
  cecho("<yellow>ap load ship <#><reset>\n")
  cecho("   Loads a ship from your saved list by its ID.\n\n")
  cecho("<yellow>ap delete ship <#><reset>\n")
  cecho("   Deletes a ship from your ship list by its ID.\n\n")
  
  -- Cargo and Route Commands
  cecho("<cyan>CARGO / ROUTE COMMANDS<reset>\n")
  cecho("<white>------------------------------------------------------------\n")
  cecho("<yellow>ap add stop <planet>:<resource><reset>\n")
  cecho("   Adds a stop to the current cargo route (format: planet:resource).\n\n")
  cecho("<yellow>ap save route<reset>\n")
  cecho("   Saves the current cargo route to your route list.\n\n")
  cecho("<yellow>ap load route <#><reset>\n")
  cecho("   Loads a cargo route from your saved list by its ID.\n\n")
  cecho("<yellow>ap delete route <#><reset>\n")
  cecho("   Deletes a cargo route from your route list by its ID.\n\n")
  cecho("<yellow>ap start cargo<reset>\n")
  cecho("   Begins a cargo run (requires ship capacity and a saved route).\n\n")
  cecho("<yellow>ap stop cargo<reset>\n")
  cecho("   Stops your cargo run.\n\n")
  cecho("<yellow>ap profit<reset>\n")
  cecho("   Show cargo hauling financial report<reset>\n\n")
  cecho("<white>------------------------------------------------------------<reset>\n")
end

function autopilot.alias.status()
  debugc("autopilot.alias.status()")
  cecho("-----------------[ <cyan>AutoPilot<reset> ]----------------\n")
  
  if next(autopilot.ship) == nil and autopilot.waypoints == nil then
    cecho("<red>No attributes set.\n")
    return
  end
  
  cecho("Ship\n")
  cecho("----------------------------------------------\n")
  if autopilot.ship then
    for key, value in pairs(autopilot.ship) do
      cecho("<green>"..key.."<reset>: ")
      if type(value) == "table" then
        local string = table.concat(value,",")
        cecho(string.."\n")
      else
        cecho(value.."\n")  
      end
    end
  end
  
  if autopilot.destination then
    cecho("<green>destination:<reset> ".. autopilot.destination.planet.."\n")
  end
  
  if autopilot.waypoints then
    cecho("<green>waypoints:<reset>\n")
    for i, waypoint in ipairs(autopilot.waypoints) do
      cecho(i.." - "..waypoint.."\n")
    end
  end
  cecho("----------------------------------------------\n")
  
  if autopilot.route then
    cecho("Route\n")
    cecho("----------------------------------------------\n")
    local stops = {}
    for _, stop in ipairs(autopilot.route) do
      table.insert(stops, "<cyan>" .. stop.planet .. "<grey>:<magenta>" .. stop.resource .. "<reset>")
    end
    cecho(table.concat(stops, " <gray>→ <reset>"))
    cecho("\n----------------------------------------------\n")
  end 
end

function autopilot.alias.fly()
  debugc("autopilot.alias.fly()")
  if matches.planets == "" then
    cecho("-----------------[ <cyan>AutoPilot<reset> ]----------------\n")
    cecho("<red>ap fly \<planet/planets\><reset>\n")
    cecho("----------------Usage Examples----------------\n")
    cecho("<yellow>ap fly planet\n")
    cecho("<yellow>ap fly planet1,planet2,planet3\n")
    cecho("<yellow>ap fly planet1, planet2, planet3\n")
    cecho("----------------------------------------------\n\n")
    return
  end
  
  autopilot.waypoints = autopilot.tableString(matches.planets)
  autopilot.destination = {}
  autopilot.destination.planet = table.remove(autopilot.waypoints, 1)
  cecho("[<cyan>AutoPilot<reset>] <yellow>Engaged<reset> | <green>Destination:<reset> "..autopilot.destination.planet.."\n")
  enableTrigger("autopilot.flight")
  send("open "..autopilot.ship.name)
end

function autopilot.alias.setShip()
debugc("autopilot.alias.setShip()")
  if matches.ship == "" then
    cecho("-----------------[ <cyan>AutoPilot<reset> ]----------------\n")
    cecho("<red>ap set name \<name\><reset>\n")
    return
  end 
  autopilot.ship.name = matches.ship
  autopilot.alias.status()   
end

function autopilot.alias.setEnter()
  debugc("autopilot.alias.setEnter()")
  if matches.commands == "" then
    cecho("-----------------[ <cyan>AutoPilot<reset> ]----------------\n")
    cecho("<red>ap set enter \<commands\><reset>\n")
    return
  end 
  autopilot.ship.enter = autopilot.tableString(matches.commands)
  autopilot.alias.status()
end

function autopilot.alias.setExit()
  debugc("autopilot.alias.setExit()")
  if matches.commands == "" then
    cecho("-----------------[ <cyan>AutoPilot<reset> ]----------------\n")
    cecho("<red>ap set exit \<commands\><reset>\n")
    return
  end
  autopilot.ship.exit = autopilot.tableString(matches.commands)
  autopilot.alias.status()
end

function autopilot.alias.setHatch()
  debugc("autopilot.alias.setHatch()")
  if matches.code == "" then
    cecho("-----------------[ <cyan>AutoPilot<reset> ]----------------\n")
    cecho("<red>ap set hatch \<code\><reset>\n")
    return
  end
  autopilot.ship.hatch = matches.code
  autopilot.alias.status()
end

function autopilot.alias.setCapacity()
  debugc("autopilot.alias.setCapacity()")
  if matches.capacity == "" then
    cecho("-----------------[ <cyan>AutoPilot<reset> ]----------------\n")
    cecho("<red>ap set capacity \<amount\><reset>\n")
    return
  end
  
  autopilot.ship.capacity = matches.capacity
  autopilot.alias.status()
end

function autopilot.alias.saveShip()
  debugc("autopilot.alias.saveShip()")
  table.insert(autopilot.ships, table.deepcopy(autopilot.ship))
  cecho("[<cyan>AutoPilot<reset>] Added: <green>"..autopilot.ship.name.."<reset>\n")
  table.save(getMudletHomeDir().."/AutoPilot.lua", autopilot)
end

function autopilot.alias.saveRoute()
  debugc("autopilot.alias.saveRoute()")
  autopilot.routes = autopilot.routes or {}
  table.insert(autopilot.routes, table.deepcopy(autopilot.route))
  table.save(getMudletHomeDir().."/AutoPilot.lua", autopilot)
  cecho("[<cyan>AutoPilot<reset>] <green>Route saved<reset>\n")
end

function autopilot.alias.loadShip()
  debugc("autopilot.alias.loadShip()")
  local index = tonumber(matches.index)
  if not index then
    cecho("+------------------------------------------------------------+\n")
    cecho("| <white>ID<reset> | <white>Ship<reset>\n")
    cecho("+------------------------------------------------------------+\n")
    for i, ship in ipairs(autopilot.ships) do
      cecho(string.format("| <white>%2d<reset> | %s\n", i, ship.name))
    end
    cecho("+------------------------------------------------------------+\n")
    cecho("<gray>Use<reset> <cyan>ap load ship <#><reset> <gray>to set ship.\n")
    return
  end
  
  if not autopilot.ships[index] then
    cecho("[<cyan>AutoPilot<reset>] <red>Invalid ID — no such ship in memory.<reset>\n")
    return
  end
  
  autopilot.ship = table.deepcopy(autopilot.ships[index])
  cecho("[<cyan>AutoPilot<reset>] <green>Ship loaded:<reset> "..autopilot.ship.name.."\n")
end

function autopilot.alias.loadRoute()
  debugc("autopilot.alias.loadRoute()")
  local index = tonumber(matches.index)
  if not index then
    cecho("+------------------------------------------------------------+\n")
    cecho("| <white>ID<reset> | <white>Route<reset>\n")
    cecho("+------------------------------------------------------------+\n")
    for i, route in ipairs(autopilot.routes) do
      local stops = {}
      for _, stop in ipairs(route) do
        table.insert(stops, "<cyan>" .. stop.planet .. "<reset>:<magenta>" .. stop.resource .. "<reset>")
      end
      cecho(string.format("| <white>%2d<reset> | %s\n", i, table.concat(stops, " <gray>→<reset> ")))
    end
    cecho("+------------------------------------------------------------+\n")
    cecho("<gray>Use<reset> <cyan>ap load route <#><reset> <gray>to select a cargo route.\n")
    return
  end

  if not autopilot.routes[index] then
    cecho("[<cyan>AutoPilot<reset>] <red>Invalid ID — no such route in memory.<reset>\n")
    return
  end

  autopilot.route = table.deepcopy(autopilot.routes[index])
  local stops = {}
  for _, stop in ipairs(autopilot.route) do
    table.insert(stops, stop.planet .. ":" .. stop.resource)
  end
  local routeString = table.concat(stops, " → ")
  cecho("[<cyan>AutoPilot<reset>] <green>Cargo manifest loaded:<reset> "..routeString.."\n")
end

function autopilot.alias.deleteShip()
  debugc("autopilot.alias.deleteShip()")
  local index = tonumber(matches.index)
  if not index then
    cecho("+------------------------------------------------------------+\n")
    cecho("| <white>ID<reset> | <white>Ship<reset>\n")
    cecho("+------------------------------------------------------------+\n")
    
    for i, ship in ipairs(autopilot.ships) do
      cecho(string.format("| <white>%2d<reset> | %s\n", i, ship.name))
    end
    cecho("+------------------------------------------------------------+\n")
    cecho("<gray>Use<reset> <cyan>ap delete ship <#><reset> <gray>to delete ship.\n")
    return
  end
  
  if not autopilot.ships[index] then
    cecho("[<cyan>AutoPilot<reset>] <red>Invalid ID — no such ship in memory.<reset>\n")
    return
  end

  table.remove(autopilot.ships, index)
  table.save(getMudletHomeDir().."/AutoPilot.lua", autopilot)
  cecho("[<cyan>AutoPilot<reset>] <red>Ship deleted.<reset>\n")
end

function autopilot.alias.deleteRoute()
  debugc("autopilot.alias.deleteRoute()")
  local index = tonumber(matches.index)
  if not index then
    cecho("+------------------------------------------------------------+\n")
    cecho("| <white>ID<reset> | <white>Route<reset>\n")
    cecho("+------------------------------------------------------------+\n")
    for i, route in ipairs(autopilot.routes) do
      local stops = {}
      for _, stop in ipairs(route) do
        table.insert(stops, "<cyan>" .. stop.planet .. "<reset>:<magenta>" .. stop.resource .. "<reset>")
      end
      cecho(string.format("| <white>%2d<reset> | %s\n", i, table.concat(stops, " <gray>→<reset> ")))
    end
    cecho("+------------------------------------------------------------+\n")
    cecho("<gray>Use<reset> <cyan>ap delete route <#><reset> <gray>to delete a cargo route.\n")
    return
  end

  if not autopilot.routes[index] then
    cecho("[<cyan>AutoPilot<reset>] <red>Invalid ID — no such route in memory.<reset>\n")
    return
  end

  table.remove(autopilot.routes, index)
  table.save(getMudletHomeDir().."/AutoPilot.lua", autopilot)
  cecho("[<cyan>AutoPilot<reset>] <red>Cargo manifest deleted.<reset>\n")
end

function autopilot.alias.clear()
  debugc("autopilot.alias.clear()")
  autopilot.ship = {}
  autopilot.waypoints = nil
  autopilot.destination = nil
  autopilot.route = nil
  cecho("-----------------[ <cyan>AutoPilot<reset> ]----------------\n")
  cecho("Cleared all attributes.\n")
end

function autopilot.alias.on()
  debugc("autopilot.alias.off()")
  cecho("[<cyan>AutoPilot<reset>] <green>Enabled<reset>\n")
  enableTrigger("autopilot.flight")
  enableTrigger("autopilot.cargo")
end

function autopilot.alias.off()
  debugc("autopilot.alias.off()")
  cecho("[<cyan>AutoPilot<reset>] <red>Disabled<reset>\n")
  disableTrigger("autopilot.flight")
  disableTrigger("autopilot.cargo")
end

function autopilot.alias.addStop()
  debugc("autopilot.alias.addStop()")
  if matches.planet == "" or matches.resource == "" then
    cecho("-----------------[ <cyan>AutoPilot<reset> ]----------------\n")
    cecho("<red>ap add stop \<planet\>:\<resource\><reset>\n")
        cecho("----------------Usage Examples----------------\n")
    cecho("<yellow>ap add stop coruscant:food\n")
    cecho("<yellow>ap add stop nal hutta:spice\n")
    return
  end
  
  local stop = {planet = matches.planet, resource = matches.resource}
  autopilot.route = autopilot.route or {}
  table.insert(autopilot.route, stop)
  cecho("[<cyan>AutoPilot<reset>] <green>Added stop: <reset>"..stop.planet.." → ".. stop.resource.."\n")
   
end

function autopilot.alias.startCargo()
  debugc("autopilot.alias.startCargo()")
  if not autopilot.ship.capacity then
    cecho("[<cyan>AutoPilot<reset>] <red>No cargo capacity set for this ship.\n")
    return
  end
  
  if not autopilot.route then
    cecho("[<cyan>AutoPilot<reset>] <red>No route set.\n")
    return
  end
  
  if #autopilot.route < 2 then
    cecho("[<cyan>AutoPilot<reset>] <red>Need at least to stops.\n")
    return
  end
  
  autopilot.runningCargo = true
  autopilot.alias.on()
  autopilot.routeIndex = 1
  autopilot.expense = 0
  autopilot.revenue = 0
  autopilot.fuelCost = 0
  autopilot.startTime = getEpoch()
  autopilot.desintation = {}
  autopilot.destination.planet = autopilot.route[autopilot.routeIndex].planet
  send("buycargo "..autopilot.ship.name.." "..autopilot.route[autopilot.routeIndex].resource.. " "..autopilot.ship.capacity)  
end

function autopilot.alias.stopCargo()
  debugc("autopilot.alias.stopCargo()")
  autopilot.runningCargo = false
  autopilot.alias.off()
end

function autopilot.trigger.openHatch()
  debugc("autopilot.trigger.openHatch()")
  send("refuel "..autopilot.ship.name)
  send("enter "..autopilot.ship.name)
  send("close")
  if autopilot.ship.enter then
    for i = 1, #autopilot.ship.enter do
      send(autopilot.ship.enter[i])
    end
  end
  send("autopilot off")
  send("pilot")
  send("launch")

end

function autopilot.trigger.launch()
  debugc("autopilot.trigger.launch()")
  enableTrigger("autopilot.trigger.showplanet")
  send("showplanet "..autopilot.destination.planet)
end

function autopilot.trigger.showplanet()
  debugc("autopilot.trigger.showplanet()")  
  autopilot.destination.system = multimatches[1].system
  autopilot.destination.x = multimatches[2].x
  autopilot.destination.y = multimatches[2].y
  autopilot.destination.z = multimatches[2].z
  disableTrigger("autopilot.trigger.showplanet") 
  local x = autopilot.destination.x + 289
  local y = autopilot.destination.y + 289
  local z = autopilot.destination.z + 289
  send("calculate '"..autopilot.destination.system.."' "..x.." "..y.." "..z) 
end

function autopilot.trigger.calculate()
  debugc("autopilot.trigger.calculate()")
  send("hyperspace")
end

function autopilot.trigger.exitHyperspace()
  debugc("autopilot.trigger.exitHyperspace()")
  send("course "..autopilot.destination.planet)
end

function autopilot.trigger.orbit()
  debugc("autopilot.trigger.orbit()")
  autopilot.destination.landIndex = 1
  send("land "..matches.planet)
end

function autopilot.trigger.restricted()
  debugc("autopilot.trigger.restricted()")
  autopilot.destination.landIndex = autopilot.destination.landIndex + 1
  send("land '"..autopilot.destination.planet.. "' "..autopilot.destination.pads[autopilot.destination.landIndex])
end

function autopilot.trigger.startLanding()
  debugc("autopilot.trigger.startLanding()")
  autopilot.destination.pads = {}
  if autopilot.destination.pad then
    tempTimer(2,[[send("land '"..autopilot.destination.planet.."' "..autopilot.destination.pads[autopilot.destination.pad])]])
    return
  end
  
  tempTimer(2, [[send("land '"..autopilot.destination.planet.. "' "..autopilot.destination.pads[autopilot.destination.landIndex])]])  
end

function autopilot.trigger.landingChoices()
  debugc("autopilot.trigger.landingChoices()")
  table.insert(autopilot.destination.pads, matches.pad) 
end

function autopilot.trigger.land()
  debugc("autopilot.trigger.land()")
  send("autopilot on")
  if autopilot.ship.exit then
    for i = 1, #autopilot.ship.exit do
      send(autopilot.ship.exit[i])
    end
  end
  send("open")
  send("leave")
  send("close "..autopilot.ship.name)
  send("refuel "..autopilot.ship.name) 
  if autopilot.runningCargo then
    send("sellcargo "..autopilot.ship.name.." "..autopilot.route[autopilot.routeIndex].resource.. " "..autopilot.ship.capacity)
    return
  end
  
  if next(autopilot.waypoints) then
    cecho("Setting destination to the next waypoint\n")
    autopilot.destination = {}
    autopilot.destination.planet = table.remove(autopilot.waypoints, 1)
    cecho("<green>Destination:<reset> "..autopilot.destination.planet.."\n")
    send("open "..autopilot.ship.name)
    return  
  end
  
  autopilot.destination = nil
  disableTrigger("autopilot.flight")
  cecho("[<cyan>AutoPilot<reset>] <yellow>Disengaged<reset> | Final Destination\n")
end

function autopilot.trigger.hyperspaceFail()
  debugc("autopilot.trigger.hyperspaceFail()")
  tempTimer(20, [[send("hyperspace")]])
end

function autopilot.trigger.fail()
  debugc("autopilot.trigger.fail()")
  send("!")
end

function autopilot.trigger.cargoPurchased()
  debugc("autopilot.trigger.cargoPurchased()")
  autopilot.expense = autopilot.expense + matches.cost
  send("open "..autopilot.ship.name)
end

function autopilot.trigger.cargoSold()
  debugc("autopilot.trigger.cargoSold()")
  autopilot.revenue = autopilot.revenue + matches.cost 
  autopilot.profit = autopilot.revenue - autopilot.expense - autopilot.fuelCost
  if #autopilot.route == autopilot.routeIndex then
    autopilot.routeIndex = 1
  else
    autopilot.routeIndex = autopilot.routeIndex + 1
  end
  autopilot.destination = {}
  autopilot.destination.planet = autopilot.route[autopilot.routeIndex].planet
  send("buycargo "..autopilot.ship.name.." "..autopilot.route[autopilot.routeIndex].resource.. " "..autopilot.ship.capacity)
end

function autopilot.trigger.refuel()
  debugc("autopilot.trigger.refuel()")
  local nocomma = matches.cost:gsub(",","")
  local cost = tonumber(nocomma)
  autopilot.fuelCost = autopilot.fuelCost + cost
end