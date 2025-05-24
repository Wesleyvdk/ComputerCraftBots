-- Mining Turtle Automation with GPS, Ender Chest, and Lava Refueling
-- All The Mods 10: Uses EnderStorage Ender Chest and Mekanism Lava Tank

-- CONFIGURATION
local floorWidth = 25
local floorLength = 21
local floorHeight = 5                               -- excluding the floor layer

local chestLocation = { x = -676, y = 58, z = -96 } -- Replace with real GPS coords
local tankLocation = { x = -675, y = 58, z = -96 }  -- Replace with real GPS coords
local fuelThreshold = 200
local emptyBucketSlot = 1
local buildingBlockSlot = 2

-- STATE
local pos = { x = 0, y = 0, z = 0 }
local direction = 0 -- 0 = north, 1 = east, 2 = south, 3 = west

-- HELPER FUNCTIONS
function UpdateGPS()
    local x, y, z = gps.locate()
    if not x then
        print("Unable to locate GPS position.")
        sleep(2)
        return
    end
    if x then
        pos.x, pos.y, pos.z = x, y, z
    end
end

function Face(dir)
    while direction ~= dir do
        turtle.turnRight()
        direction = (direction + 1) % 4
    end
end

function GoTo(target)
    print("Going to target...")
    UpdateGPS()
    -- move in Y
    while pos.y < target.y do
        turtle.up(); UpdateGPS()
    end
    while pos.y > target.y do
        turtle.down(); UpdateGPS()
    end

    -- move in X
    if pos.x ~= target.x then
        if target.x > pos.x then
            face(1) -- east
        else
            face(3) -- west
        end
        while pos.x ~= target.x do
            turtle.forward()
            UpdateGPS()
        end
    end

    -- move in Z
    if pos.z ~= target.z then
        if target.z > pos.z then
            face(2) -- south
        else
            face(0) -- north
        end
        while pos.z ~= target.z do
            turtle.forward()
            UpdateGPS()
        end
    end
end

function RefuelInitial()
    print("Refueling initial fuel...")
    turtle.select(emptyBucketSlot)
    turtle.refuel(1)
    print("Refueled. Current fuel: ", turtle.getFuelLevel())
end

function RefuelIfNeeded()
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

function DumpInventory()
    print("Dumping inventory into Ender Chest...")
    for i = 1, 16 do
        turtle.select(i)
        turtle.drop()
    end
end

function MineLayer()
    print("Starting excavation of layer...")
    for w = 1, floorWidth do
        for l = 1, floorLength - 1 do
            turtle.dig()
            turtle.forward()
            turtle.digUp()
        end
        if w < floorWidth then
            if w % 2 == 1 then
                face((direction + 1) % 4)
            else
                face((direction + 3) % 4)
            end
            turtle.dig()
            turtle.forward()
            turtle.digUp()
            if w % 2 == 1 then
                face((direction + 1) % 4)
            else
                face((direction + 3) % 4)
            end
        end
    end
end

function DigFloor(depth)
    for h = 1, depth do
        MineLayer()
        if h < depth then
            turtle.digDown()
            turtle.down()
        end
    end
end

-- MAIN ROUTINE
print("Starting mining turtle program...")
peripheral.getNames()
UpdateGPS()
RefuelInitial()

while true do
    if turtle.getFuelLevel() < fuelThreshold then
        GoTo(tankLocation)
        RefuelIfNeeded()
    end
    GoTo(chestLocation)
    DumpInventory()
    GoTo(pos) -- Return to previous position (save as needed)
    DigFloor(floorHeight)
    print("Layer complete. Returning to top to repeat or exit.")
    break -- Remove break to repeat for more layers
end
