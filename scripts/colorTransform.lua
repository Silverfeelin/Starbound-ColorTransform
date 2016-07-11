require "/scripts/keybinds.lua"

colorTransform = {}

function colorTransform.update(args)
  local debugActivate = colorTransform.getCurrentTransformation().direction ~= 1 and "activate" or "deactivate"
  sb.setLogMap("^orange;Color Transform^reset;", "^yellow;Press '" .. colorTransform.config.keys.activate .. "' to " .. debugActivate .. " ^orange;" .. colorTransform.logName .. "^yellow;.^reset;")
  local colorFound = false
  local dir = ""

  for orig,color in pairs(colorTransform.colors) do
    if color.stepsLeft > 0 then
      local current = {}
      color.stepsLeft = color.stepsLeft - 1
      for i,v in ipairs(color.current) do
        color.current[i] = colorTransform.clamp(v + color.steps[i])
        current[i] = colorTransform.clamp(math.ceil(color.current[i]))
      end
      dir = dir .. ";" .. orig .. "=" .. colorTransform.rgb2hex(current)
    end
  end
  if dir ~= "" then
    sb.setLogMap("^orange;Color Transform^reset;", "^yellow;A transformation is active.^reset;")
    tech.setParentDirectives("?replace" .. dir)
  end
end

local oldUpdate = update
update = function(args)
  oldUpdate(args)
  colorTransform.update(args)
end

function colorTransform.initializeTransformations()
  for _,transformation in ipairs(colorTransform.config.transformations) do
    transformation.steps = {}
    transformation.fromColors = {}
    transformation.toColors = {}
    transformation.direction = -1
    for hexFrom,hexTo in pairs(transformation.colors) do
      local from, to = colorTransform.hexToColor(hexFrom), colorTransform.hexToColor(hexTo)
      table.insert(transformation.fromColors, from)
      table.insert(transformation.toColors, to)
      table.insert(transformation.steps, {
        (to[1] - from[1]) / transformation.duration,
        (to[2] - from[2]) / transformation.duration,
        (to[3] - from[3]) / transformation.duration
      })
    end
  end
end

function colorTransform.getCurrentTransformation()
  return colorTransform.getTransformation(colorTransform.index)
end
function colorTransform.getTransformation(index)
  return colorTransform.config.transformations[index]
end

function colorTransform.clamp(i)
  if i > 255 then
    return 255
  elseif i < 0 then
    return 0
  else
    return i
  end
end

function colorTransform.hexToColor(hex)
  return {
    tonumber(string.sub(hex, 1,2), 16),
    tonumber(string.sub(hex, 3,4), 16),
    tonumber(string.sub(hex, 5,6), 16)
    }
end

function colorTransform.rgb2hex(tbl)
  return colorTransform.num2hex(tbl[1]) .. colorTransform.num2hex(tbl[2]) .. colorTransform.num2hex(tbl[3])
end

--http://www.emoticode.net/lua/number-to-hex.html
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

--http://lua-users.org/wiki/CopyTable
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

function colorTransform.toggle()
  colorTransform.index = colorTransform.index + 1 <= #colorTransform.config.transformations and colorTransform.index + 1 or 1
  colorTransform.logName = colorTransform.getTransformation(colorTransform.index).name or "Unnamed"
  colorTransform.getTransformation(colorTransform.index).direction = -1
end

colorTransform.config = root.assetJson("/colorTransform.json")
if not colorTransform.config or #colorTransform.config.transformations == 0 then
  sb.logWarn("Color Transform: Could not find any transformations!")
  return
end

-- Default data.
colorTransform.colors = {}
colorTransform.index = 1
colorTransform.initializeTransformations()
colorTransform.logName = colorTransform.getTransformation(colorTransform.index).name or "Unnamed"

-- Create binds for activating and scrolling between available transformations.
Bind.create(colorTransform.config.keys.activate, colorTransform.activate, false)
Bind.create(colorTransform.config.keys.toggle, colorTransform.toggle, false)
