-- Mining Turtle Automation with GPS, Ender Chest, and Lava Refueling
-- All The Mods 10: Uses EnderStorage Ender Chest and Mekanism Lava Tank

-- CONFIGURATION
local floorWidth = 25
local floorLength = 21
local floorHeight = 5 -- excluding the floor layer

local chestLocation = { x = -676, y = 58, z = -96 } -- Replace with real GPS coords
local tankLocation = { x = -675, y = 58, z = -96 }  -- Replace with real GPS coords
local fuelThreshold = 200
local emptyBucketSlot = 1

-- STATE
local pos = {x = 0, y = 0, z = 0}
local direction = 0 -- 0 = north, 1 = east, 2 = south, 3 = west
local path = {} -- stores movement history

-- HELPER FUNCTIONS
function updateGPS()
  print("Updating GPS...")
  local x, y, z = gps.locate(2)
  if not x then
    print("GPS failed! Retrying in 2s...")
    sleep(2)
    return false
  end
  pos.x, pos.y, pos.z = x, y, z
  return true
end

function face(dir)
  while direction ~= dir do
    turtle.turnRight()
    direction = (direction + 1) % 4
  end
end

function moveForward()
  if turtle.forward() then
    if direction == 0 then pos.z = pos.z - 1
    elseif direction == 1 then pos.x = pos.x + 1
    elseif direction == 2 then pos.z = pos.z + 1
    elseif direction == 3 then pos.x = pos.x - 1 end
    table.insert(path, "forward")
    return true
  end
  return false
end

function moveDown()
  if turtle.down() then
    pos.y = pos.y - 1
    table.insert(path, "down")
    return true
  end
  return false
end

function moveUp()
  if turtle.up() then
    pos.y = pos.y + 1
    table.insert(path, "up")
    return true
  end
  return false
end

function backtrack()
  for i = #path, 1, -1 do
    local move = path[i]
    if move == "forward" then
      turtle.back()
      if direction == 0 then pos.z = pos.z + 1
      elseif direction == 1 then pos.x = pos.x - 1
      elseif direction == 2 then pos.z = pos.z - 1
      elseif direction == 3 then pos.x = pos.x + 1 end
    elseif move == "up" then
      turtle.down()
      pos.y = pos.y - 1
    elseif move == "down" then
      turtle.up()
      pos.y = pos.y + 1
    end
  end
  path = {}
end

function refuelIfNeeded()
  if turtle.getFuelLevel() > fuelThreshold then return end
  print("Refueling...")
  turtle.select(emptyBucketSlot)
  if turtle.place() then -- try to fill from Mekanism tank
    turtle.refuel(1)
    print("Refueled. Current fuel: ", turtle.getFuelLevel())
  else
    print("Failed to get lava from tank.")
  end
end

function RefuelInitial()
  print("Refueling initial fuel...")
  turtle.select(emptyBucketSlot)
  turtle.refuel(1)
  print("Refueled. Current fuel: ", turtle.getFuelLevel())
end

function dumpInventory()
  print("Dumping inventory into Ender Chest...")
  for i = 1, 16 do
    turtle.select(i)
    turtle.drop()
  end
end

function mineLayer()
  print("Starting excavation of layer...")
  for w = 1, floorWidth do
    for l = 1, floorLength - 1 do
      turtle.dig()
      moveForward()
      turtle.digUp()
    end
    if w < floorWidth then
      if w % 2 == 1 then face((direction + 1) % 4)
      else face((direction + 3) % 4) end
      turtle.dig()
      moveForward()
      turtle.digUp()
      if w % 2 == 1 then face((direction + 1) % 4)
      else face((direction + 3) % 4) end
    end
  end
end

function digFloor(depth)
  for h = 1, depth do
    mineLayer()
    if h < depth then
      turtle.digDown()
      moveDown()
    end
  end
end

function goTo(target)
    updateGPS()
  
    -- Move in Y first (up/down)
    while pos.y < target.y do
      moveUp()
    end
    while pos.y > target.y do
      moveDown()
    end
  
    -- Move in X (east-west)
    if pos.x < target.x then
      face(1) -- east
      while pos.x < target.x do moveForward() end
    elseif pos.x > target.x then
      face(3) -- west
      while pos.x > target.x do moveForward() end
    end
  
    -- Move in Z (north-south)
    if pos.z < target.z then
      face(2) -- south
      while pos.z < target.z do moveForward() end
    elseif pos.z > target.z then
      face(0) -- north
      while pos.z > target.z do moveForward() end
    end
  end

-- MAIN ROUTINE
print("Starting mining turtle program...")
if not updateGPS() then error("GPS unavailable. Aborting.") end
RefuelInitial()

while true do
  if turtle.getFuelLevel() < fuelThreshold then
    backtrack()
    updateGPS()
    goTo(tankLocation)
    refuelIfNeeded()
    goTo(chestLocation)
    dumpInventory()
    break
  end
  digFloor(floorHeight)
  print("Layer complete. Returning to top to repeat or exit.")
  backtrack()
  break -- Remove break to repeat for more layers
end
