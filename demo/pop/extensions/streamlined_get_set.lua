local graphics
graphics = love.graphics
local sub, len
do
  local _obj_0 = string
  sub, len = _obj_0.sub, _obj_0.len
end
local path = sub(..., 1, len(...) - len("/extensions/streamlined_get_set"))
local element = require(tostring(path) .. "/elements/element")
element.__base.position = function(self, x, y)
  if x or y then
    return self:setPosition(x, y)
  else
    return self:getPosition()
  end
end
element.__base.size = function(self, w, h)
  if w or h then
    return self:setSize(w, h)
  else
    return self:getSize()
  end
end
element.__base.width = function(self, w)
  if w then
    return self:setWidth(w)
  else
    return self:getWidth()
  end
end
element.__base.height = function(self, h)
  if h then
    return self:setHeight(h)
  else
    return self:getHeight()
  end
end
element.__base.alignment = function(self, horizontal, vertical)
  if horizontal or vertical then
    return self:setAlignment(horizontal, vertical)
  else
    return self:getAlignment()
  end
end
element.__base.margin = function(self, m)
  if m then
    return self:setMargin(m)
  else
    return self:getMargin()
  end
end
