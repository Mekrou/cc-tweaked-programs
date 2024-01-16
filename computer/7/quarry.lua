-- initialize sending debug messages
rednet.open("left")
rednet.host("debug", "miner0")

DIAMETER = 6
DEBUG_MESSAGES = {}

function log(message)
  table.insert(DEBUG_MESSAGES, message)
end

local direction_meta = {
  __tostring = function(direction)
    return direction.posOrNeg..direction.axis
  end,
  __eq = function(a,b)
    if (a.posOrNeg == b.posOrNeg) and (a.axis == b.axis) then
      return true
    else
      return false
    end
  end,
}

function Direction(posOrNeg, axis)
  if posOrNeg > 0 then
    posOrNeg = "+"
  elseif posOrNeg < 0 then
    posOrNeg = "-"
  end
  local d = {
    axis = axis or nil,
    posOrNeg = posOrNeg or nil
  }

  setmetatable(d, direction_meta)
  return d
end

-- the square, excluding the border
INNER_DIAMETER = DIAMETER - 2

-- Directions are significant when they're non-zero.
function getSignificantDirection(directionVector)
  for k, v in pairs(directionVector) do
     if v ~= 0 then
       return v,k
     end
  end
end

function getFacingDirection()
  local x,y,z = gps.locate()
  local x2,y2,z2 = 0,0,0

  if (turtle.forward()) then
    x2,y2,z2 = gps.locate()
    turtle.back()
  else
    turtle.dig()
    turtle.forward()
    x2,y2,z2 = gps.locate()
    turtle.back()
  end

  local directionVector = { x = x2 - x, y = y2 - y, z = z2 - z}
  local posOrNeg,axis = getSignificantDirection(directionVector)
  local direction = Direction(posOrNeg, axis)
  log(tostring(direction))
  return direction
end

function faceTowards(direction)
  repeat
    turtle.turnRight()
    currDir = getFacingDirection()
  until currDir == direction
end

function matchYPos(y)
  currX, currY, currZ = gps.locate()
  while (currY ~= y) do
    local difference = y - currY
    if (difference > 0) then
      if (turtle.up()) then

      else
        -- debugLog("turtle.up() failed!")
        turtle.digUp()
        turtle.up()
      end
    else
      if (difference < 0) then
        if (turtle.down()) then

        else
          -- debugLog("turtle.down() failed!")
          turtle.digDown()
          turtle.down()
        end
      end
    end
    currX, currY, currZ = gps.locate()
  end
    log("matched Y POS!")
  return true
end

function matchXPos(x)
  currX, currY, currZ = gps.locate()
  local difference = x - currX
  if difference ~= 0 then
    local dir = Direction(difference, 'x')
    faceTowards(dir)
    repeat
        turtle.dig()
        turtle.forward()
        currX = gps.locate()
    until currX == x
  end
  log("matched X Pos!")
  return true
end

function matchZPos(z)
    _, _, currZ = gps.locate()
    local difference = z - currZ
    if difference ~= 0 then
      local dir = Direction(difference, 'z')
      faceTowards(dir)
      repeat
          turtle.dig()
          turtle.forward()
          _,_,currZ = gps.locate()
      until currZ == z
    end
    log("matched Z Pos!")
    return true
end

function moveToPos(x,y,z)
  local foundY = false
  local foundX = false
  local foundZ = false

  --while not foundX and not foundY and not foundZ do
  while not foundY and not foundX and not foundZ do
    -- Handle Y-axis movement
    foundY = matchYPos(y)

    -- Handle X-axis movement
    foundX = matchXPos(x)

    foundZ = matchZPos(z)
  end
end

function digMoveForward(steps)
  for i = 1, steps do
    turtle.dig()
    turtle.forward()
  end
end

function minePlane()
  -- Startup
  digMoveForward(DIAMETER)

  -- Second Step is always unique
  turtle.turnLeft()
  digMoveForward(math.floor(DIAMETER / 2))

  --
  for i = 1, 3 do
    turtle.turnLeft()
    digMoveForward(DIAMETER - 1)
  end

  turtle.turnLeft()

  digMoveForward(1)
  turtle.turnLeft()

  -- inner grid
  local step = INNER_DIAMETER
  local flag = 0
  -- first iter is always unique
  digMoveForward(step)
  step = step - 1
  while true do
    turtle.turnRight()
    digMoveForward(step)
    flag = flag + 1
    if flag == 2 then
      flag = 0
      step = step - 1
    end

    if step == 0 then
      digMoveForward(step)
      break
    end
  end
end

function goDownOnePlane()
  turtle.digDown()
  turtle.down()
end

function main()
  x,y,z = gps.locate()
  local init_dir = getFacingDirection()
  log("main restarted at "..x.." "..y.." "..z)
  
  while true do
    minePlane()
    moveToPos(x,y,z)
    faceTowards(init_dir)
    goDownOnePlane()
    y = y - 1
  end
end

function checkDebugServer()
  while true do
    local id, message = rednet.receive("debug", 1)
    if message == 33 then
      rednet.broadcast(DEBUG_MESSAGES, "debugMessage")
      DEBUG_MESSAGES = {}
    end
  end
end

while true do
  parallel.waitForAny(main, checkDebugServer)
end
