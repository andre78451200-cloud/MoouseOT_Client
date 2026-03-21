-- Farm System for Client
-- This contains the same farm data as the server for position checking

FARM_SYSTEM = {}

-- Farm data (must match server-side data)
FARM_SYSTEM.Farms = {
    farmSmall = {
        name = "Farm Small",
        price = 177839370,
        size = {width = 5, height = 3},
        icon = "/images/ui/windows/house/preview/icons/farming",
        entrancePosition = {x = 32461, y = 32208, z = 7},
        farmCost = 1000,
        centerPosition = {x = 32459, y = 32204, z = 7},
        range = {x = 5, y = 3},
        height = 1,
        depth = 0,
        isSpecial = true,
        baseTile = 4515,
        items = {
            {name = "wood", amount = 10, icon = "/images/ui/icons/wood", id = 5901},
            {name = "nail", amount = 30, icon = "/images/ui/icons/nail", id = 953},
            {name = "wooden hammer", amount = 1, icon = "/images/ui/icons/hammer", id = 2553},
            {name = "rope", amount = 5, icon = "/images/ui/icons/rope", id = 2120},
            {name = "leather", amount = 3, icon = "/images/ui/icons/leather", id = 5878}
        },
        chickenArea = {
            chickenEntrance = {x = 32477, y = 32196, z = 7},
            chickenCenter = {x = 32480, y = 32196, z = 7},
            chickenRange = {x = 5, y = 3},
            chickenStorage = 6301001
        },
        pigArea = {
            pigEntrance = {x = 32518, y = 32206, z = 7},
            pigCenter = {x = 32523, y = 32206, z = 7},
            pigRange = {x = 6, y = 4},
            pigStorage = 6301002
        }
    },
    farmMedium = {
        name = "Farm Medium",
        price = 177839370,
        size = {width = 7, height = 5},
        icon = "/images/ui/windows/house/preview/icons/farming",
        entrancePosition = {x = 32461, y = 32208, z = 7},
        farmCost = 2000,
        centerPosition = {x = 32459, y = 32204, z = 7},
        range = {x = 7, y = 5},
        height = 1,
        depth = 0,
        isSpecial = true,
        baseTile = 4515,
        items = {
            {name = "wood", amount = 20, icon = "/images/ui/icons/wood", id = 5901},
            {name = "nail", amount = 50, icon = "/images/ui/icons/nail", id = 953},
            {name = "stone", amount = 15, icon = "/images/ui/icons/stone", id = 203},
            {name = "rope", amount = 8, icon = "/images/ui/icons/rope", id = 2120},
            {name = "leather", amount = 5, icon = "/images/ui/icons/leather", id = 5878},
            {name = "iron", amount = 10, icon = "/images/ui/icons/iron", id = 8307}
        }
    },
    farmLarge = {
        name = "Farm Large",
        price = 177839370,
        size = {width = 10, height = 8},
        icon = "/images/ui/windows/house/preview/icons/farming",
        entrancePosition = {x = 32461, y = 32208, z = 7},
        farmCost = 5000,
        centerPosition = {x = 32459, y = 32204, z = 7},
        range = {x = 10, y = 8},
        height = 1,
        depth = 0,
        isSpecial = true,
        baseTile = 4515,
        items = {
            {name = "wood", amount = 50, icon = "/images/ui/icons/wood", id = 5901},
            {name = "nail", amount = 100, icon = "/images/ui/icons/nail", id = 953},
            {name = "stone", amount = 30, icon = "/images/ui/icons/stone", id = 203},
            {name = "iron", amount = 20, icon = "/images/ui/icons/iron", id = 8307},
            {name = "rope", amount = 15, icon = "/images/ui/icons/rope", id = 2120},
            {name = "leather", amount = 10, icon = "/images/ui/icons/leather", id = 5878},
            {name = "gold", amount = 5, icon = "/images/ui/icons/gold", id = 2148},
            {name = "crystal", amount = 3, icon = "/images/ui/icons/crystal", id = 2146}
        }
    }
}

-- Helper function to check if two positions are equal
function FARM_SYSTEM.positionsEqual(pos1, pos2)
    if not pos1 or not pos2 then
        return false
    end
    
    -- Handle both Position objects and tables
    local x1, y1, z1 = pos1.x or pos1:getX(), pos1.y or pos1:getY(), pos1.z or pos1:getZ()
    local x2, y2, z2 = pos2.x or pos2:getX(), pos2.y or pos2:getY(), pos2.z or pos2:getZ()
    
    return x1 == x2 and y1 == y2 and z1 == z2
end

print("DEBUG: Farm system loaded for client")
