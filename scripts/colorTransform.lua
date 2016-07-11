require "/scripts/keybinds.lua"

colorTransform = {}

---------------------
-- Update Callback --
---------------------

--[[
  Script update callback. Handles transformations per color.
]]
function colorTransform.update(args)
  local debugActivate = colorTransform.getCurrentTransformation().direction ~= 1 and "activate" or "deactivate"
  sb.setLogMap("^orange;Color Transform^reset;", "^yellow;Press '" .. colorTransform.config.keys.activate .. "' to " .. debugActivate .. " ^orange;" .. colorTransform.logName .. "^yellow;.^reset;")
  local colorFound = false
  local dir = ""
  local active = false
  for orig,color in pairs(colorTransform.colors) do
      local current = {}
      color.stepsLeft = color.stepsLeft - 1
      for i,v in ipairs(color.current) do
        if color.stepsLeft > 0 then
          active = true
          color.current[i] = colorTransform.clamp(v + color.steps[i], 0, 255)
        end
        current[i] = colorTransform.clamp(math.ceil(color.current[i]), 0, 255)
      end
      dir = dir .. ";" .. orig .. "=" .. colorTransform.rgb2hex(current)
  end
  if active then
    sb.setLogMap("^orange;Color Transform^reset;", "^yellow;A transformation is active.^reset;")
    tech.setParentDirectives("?replace" .. dir)
  end
end

-- Insert update callback.
local oldUpdate = update
update = function(args)
  oldUpdate(args)
  colorTransform.update(args)
end

-------------------------------
-- Color Transform functions --
-------------------------------

--[[
  Initialize all transformations from the config.
  Converts the original and target colors to RGB tables, so the script can
  read them.
]]
function colorTransform.initializeTransformations()
  for _,transformation in ipairs(colorTransform.config.transformations) do
    transformation.steps = {}
    transformation.fromColors = {}
    transformation.toColors = {}
    transformation.direction = -1
    for hexFrom,hexTo in pairs(transformation.colors) do
      local from, to = colorTransform.hex2rgb(hexFrom), colorTransform.hex2rgb(hexTo)
      table.insert(transformation.fromColors, from)
      table.insert(transformation.toColors, to)
    end
  end
end

--[[
  Returns the currently selected transformation.
  @return - Selected transformation details.
]]
function colorTransform.getCurrentTransformation()
  return colorTransform.getTransformation(colorTransform.index)
end

--[[
  Returns the transformation at the given index in
  colorTransform.config.transformations'.
  @return - Transformation details at the given index.
]]
function colorTransform.getTransformation(index)
  return colorTransform.config.transformations[index]
end

------------------------------
-- Color Transform Keybinds --
------------------------------

--[[
  Keybind callback. Activates the selected transformation after toggling the
  direction. Calculates the steps by using the current color values, to allow
  smooth transitions between transformations before they ended.
]]
function colorTransform.activate()
  local transformation = colorTransform.getTransformation(colorTransform.index)
  transformation.direction = transformation.direction ~= 1 and 1 or -1
  local i = 1
  for k,_ in pairs(transformation.colors) do
    local color = colorTransform.colors[k]
    color  = color or {}
    if not color.current then
      color.current = transformation.direction == 1 and colorTransform.deepCopy(transformation.fromColors[i]) or colorTransform.deepCopy(transformation.toColors[i])
    end
    color.target = transformation.direction == 1 and colorTransform.deepCopy(transformation.toColors[i]) or colorTransform.deepCopy(transformation.fromColors[i])

    color.steps = {
      (color.target[1] - color.current[1]) / transformation.duration,
      (color.target[2] - color.current[2]) / transformation.duration,
      (color.target[3] - color.current[3]) / transformation.duration
    }

    color.stepsLeft = transformation.duration

    colorTransform.colors[k] = color
    i = i + 1
  end
end

--[[
  Keybind callback. Selects the next available transformation, but does not
  activate it.
  Resets the direction to left for the next activation to toggle it to the right.
]]
function colorTransform.toggle()
  colorTransform.index = colorTransform.index + 1 <= #colorTransform.config.transformations and colorTransform.index + 1 or 1
  colorTransform.logName = colorTransform.getTransformation(colorTransform.index).name or "Unnamed"
  colorTransform.getTransformation(colorTransform.index).direction = -1
end

----------------------
-- Useful functions --
----------------------

--[[
  Clamps the given value between the minimum and maximum value.
  @param value - Value to clamp.
  @param min - Lower bound. Result can not be smaller than this.
  @param max - Upper bound. Result can not be bigger than this.
  @return - Clamped number.
]]
function colorTransform.clamp(value, min, max)
  if min > max then min, max = max, min end
  return math.min(math.max(value, min), max)
end

--[[
  Creates a copy of the given table and all nested tables.
  Source: http://lua-users.org/wiki/CopyTable
  @param orig - Table to copy.
  @return - Copy of the table.
]]
function colorTransform.deepCopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[colorTransform.deepCopy(orig_key)] = colorTransform.deepCopy(orig_value)
        end
        setmetatable(copy, colorTransform.deepCopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

--[[
  Converts the given hexadecimal color string to a rgb table.
  See also: colorTransform.rgb2hex(tbl)
  @param hex - 6-digit hexadecimal string, representing a color.
  @return - RGB table formatted { r, g ,b }. Each value represents an unsigned
  byte (0-255).
]]
function colorTransform.hex2rgb(hex)
  return {
    tonumber(string.sub(hex, 1,2), 16),
    tonumber(string.sub(hex, 3,4), 16),
    tonumber(string.sub(hex, 5,6), 16)
    }
end

--[[
  Converts the given rgb table to a hexadecimal string.
  See also: colorTransform.hex2rgb(hex)
  @param tbl - RGB table formatted { r, g ,b }. Each value should be an
  unsigned byte (0-255).
  @return - 6-digit hexadecimal string, representing the given color.
]]
function colorTransform.rgb2hex(tbl)
  return colorTransform.num2hex(tbl[1]) .. colorTransform.num2hex(tbl[2]) .. colorTransform.num2hex(tbl[3])
end

--[[
  Converts the given integer to a hexadecimal representatation of it.
  Adds a leading '0' if the result is one digit.
  Source: http://www.emoticode.net/lua/number-to-hex.html
  @param num - Integer to convert.
  @return - Hexadecimal number.
]]
function colorTransform.num2hex(num)
    local hexstr = "0123456789abcdef"
    local s = ""
    while num > 0 do
        local mod = math.fmod(num, 16)
        s = string.sub(hexstr, mod+1, mod+1) .. s
        num = math.floor(num / 16)
    end
    if s == "" then s = "00" end
    if string.len(s) == 1 then s = "0" .. s end
    return s
end

------------------------------------
-- Color Transform Initialization --
------------------------------------

colorTransform.config = root.assetJson("/colorTransform.json")
if not colorTransform.config or #colorTransform.config.transformations == 0 then
  sb.logWarn("Color Transform: Could not find any transformations!")
  return
end

colorTransform.colors = {}
colorTransform.index = 1
colorTransform.initializeTransformations()
colorTransform.logName = colorTransform.getTransformation(colorTransform.index).name or "Unnamed"

-- Create binds for activating and scrolling between available transformations.
Bind.create(colorTransform.config.keys.activate, colorTransform.activate, false)
Bind.create(colorTransform.config.keys.toggle, colorTransform.toggle, false)
