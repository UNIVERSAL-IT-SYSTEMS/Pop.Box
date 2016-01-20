local lf = love.filesystem
local lg = love.graphics
local path = ...

local pop = {}
pop.elementClasses = {}
--pop.elements = {}
pop.window = false --top level element, defined in pop.load()
pop.skins = {}
pop.currentSkin = "clear"

function pop.load()
    -- load element classes
    local elementList = lf.getDirectoryItems(path .. "/elements")

    for i=0, #elementList do
        local name = elementList[i]:sub(1, -5)
        pop.elementClasses[name] = require(path .. "/elements/" .. name)

        -- wrapper to be able to call pop.element() to create elements
        if not pop[name] then
            pop[name] = function(...) return pop.create(name, ...) end
        end
    end

    -- load skins
    local skinList = lf.getDirectoryItems(path .. "/skins")

    for i=0, #skinList do
        local name = skinList[i]:sub(1, -5)
        pop.skins[name] = require(path .. "/skins/" .. name)
        pop.skins[name].name = name
    end

    -- set top element
    pop.window = pop.create("box"):setSize(lg.getWidth(), lg.getHeight())
end

function pop.create(elementType, parent, ...)
    if not parent then
        parent = pop.window
    end

    local newElement = pop.elementClasses[elementType](pop, parent, ...)
    table.insert(parent.child, newElement) --NOTE pop.window is its own parent!

    return newElement
end

function pop.update(dt, element)
    if not element then
        element = pop.window
    end

    if element.update then
        element:update(dt)
    end

    --TODO redo this loop
    for _, childElement in pairs(element.child) do
        pop.update(dt, childElement)
    end
end

function pop.draw(element)
    if not element then
        element = pop.window
    end

    if element.skin.draw and element.skin.draw(element) then
        -- do nothing...
    elseif element.draw then
        element:draw()
    end

    --TODO redo this loop
    for _, childElement in pairs(element.child) do
        pop.draw(childElement)
    end
end

function pop.mousepressed(button, x, y)
    --TODO find element, if it has a callback, call with button and LOCAL x/y
end

function pop.mousereleased(button, x, y)
    --TODO find element, if it has a callback, call with button and LOCAL x/y
end

function pop.keypressed(key)
    --TODO no idea what to do with this
end

function pop.keyreleased(key)
    --TODO no idea what to do with this
end

pop.load()

return pop
