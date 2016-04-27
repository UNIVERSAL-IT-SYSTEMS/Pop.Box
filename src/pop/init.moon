pop = {
    _VERSION: 'Pop.Box v0.0.0'
    _DESCRIPTION: 'GUI library for LOVE, designed for ease of use'
    _URL: 'http://github.com/Guard13007/Pop.Box'
    _LICENSE: 'The MIT License (MIT)'
    _AUTHOR: 'Paul Liverman III'
}

unless love.getVersion
    error "Pop.Box only supports LOVE versions >= 0.9.1"

import filesystem, graphics from love
import insert from table
import inheritsFromElement from require "#{...}/util"

path = ...

pop.elements = {}
pop.skins = {}

pop.screen = false  -- initialized in pop.load()
pop.focused = false

-- loads elements and skins, creates pop.screen (intended to only be called once at the beginning)
pop.load = ->
    elements = filesystem.getDirectoryItems "#{path}/elements"

    for i = 1, #elements
        -- only attempt to load lua files
        unless elements[i]\sub(-4) == ".lua"
            continue

        -- load into pop.elements table
        name = elements[i]\sub 1, -5
        pop.elements[name] = require "#{path}/elements/#{name}"

        if pop.elements[name].load
            pop.elements[name].load pop

        print "element loaded: \"#{name}\""

        -- create pop.element() wrapper if possible
        unless pop[name]
            if pop.elements[name].wrap
                pop[name] = pop.elements[name].wrap pop
            else
                pop[name] = (...) ->
                    return pop.create(name, ...)

            print "wrapper created: \"pop.#{name}()\""

    -- works just like above, except no load calls or wrappers
    skins = filesystem.getDirectoryItems "#{path}/skins"

    for i = 1, #skins
        unless skins[i]\sub(-4) == ".lua"
            continue

        name = skins[i]\sub 1, -5
        pop.skins[name] = require "#{path}/skins/#{name}"

        print "skin loaded: \"#{name}\""

    -- (again, similar) load extensions by just running them via require
    extensions = filesystem.getDirectoryItems "#{path}/extensions"

    for i = 1, #extensions
        unless extensions[i]\sub(-4) == ".lua"
            continue

        name = extensions[i]\sub 1, -5
        require "#{path}/extensions/#{name}"

        print "extension loaded: \"#{name}\""

    -- GUI screen area
    pop.screen = pop.create("element", false)\setSize(graphics.getWidth!, graphics.getHeight!)
    print "created \"pop.screen\""

-- creates an element (parent is an element, false, or nil (defaults to pop.screen))
pop.create = (element, parent=pop.screen, ...) ->
    -- if valid parent element
    if inheritsFromElement parent
        element = pop.elements[element](parent, ...)
        insert parent.child, element
    -- if explicitly no parent
    elseif parent == false
        element = pop.elements[element](false, ...)
    -- else use pop.screen, and "parent" is actually first argument
    else
        element = pop.elements[element](pop.screen, parent, ...)
        insert pop.screen.child, element

    return element

pop.update = (dt, element=pop.screen) ->
    unless element.excludeUpdate
        if element.update
            element\update dt
        for i = 1, #element.child
            pop.update dt, element.child[i]

pop.draw = (element=pop.screen) ->
    unless element.excludeDraw
        if element.draw
            element\draw!
        for i = 1, #element.child
            pop.draw element.child[i]

--TODO implement a way for an element to attach itself to mousemoved events
pop.mousemoved = (x, y, dx, dy) ->
    if pop.focused and pop.focused.mousemoved
        return pop.focused\mousemoved x, y, dx, dy

    return false

pop.mousepressed = (x, y, button, element) ->
    -- start at the screen, print that we received an event
    unless element
        print "mousepressed", x, y, button
        element = pop.screen

    -- have we handled the event?
    handled = false

    -- if it was inside the current element..
    if (x >= element.x) and (x <= element.x + element.w) and (y >= element.y) and (y <= element.y + element.h)
        -- check its child elements in reverse order, returning if something handles it
        for i = #element.child, 1, -1
            if handled = pop.mousepressed x, y, button, element.child[i]
                return handled

        -- if a child hasn't handled it yet
        unless handled
            -- if we can handle it and are visible, try to handle it, and set pop.focused
            if element.mousepressed and (not element.excludeDraw)
                if handled = element\mousepressed x - element.x, y - element.y, button
                    pop.focused = element

    -- return whether or not we have handled the event
    return handled

pop.mousereleased = (x, y, button, element) ->
    -- we are trying to handle a clicked or mousereleased event
    clickedHandled = false
    mousereleasedHandled = false

    -- if we have an element, and are within its bounds
    if element
        if (x >= element.x) and (x <= element.x + element.w) and (y >= element.y) and (y <= element.y + element.h)
            -- check its children in reverse for handling a clicked or mousereleased event
            for i = #element.child, 1, -1
                clickedHandled, mousereleasedHandled = pop.mousereleased x, y, button, element.child[i]
                if clickedHandled or mousereleasedHandled
                    return clickedHandled, mousereleasedHandled

            -- if that doesn't work, we try to handle it ourselves
            unless clickedHandled or mousereleasedHandled
                -- clicked only happens on visible elements, mousereleased happens either way
                if element.clicked and (not element.excludeDraw)
                    clickedHandled = element\clicked x - element.x, y - element.y, button
                if element.mousereleased
                    mousereleasedHandled = element\mousereleased x - element.x, y - element.y, button

                -- if we clicked, we're focused!
                if clickedHandled
                    pop.focused = element
                    --NOTE this might cause an error in the above for loop!
                    -- basically, move focused element to front of its parent's child
                    --element.parent\focusChild element
                    --table.insert element.parent, element.parent\removeChild(element),

    -- else, default to pop.screen to begin! (and print that we received an event)
    else
        print "mousereleased", x, y, button
        pop.mousereleased x, y, button, pop.screen

    return clickedHandled, mousereleasedHandled

pop.keypressed = (key) ->
    print "keypressed", key

    -- keypressed events must be on visible elements
    element = pop.focused
    if element and element.keypressed and (not element.excludeDraw)
        return element.keypressed key

    return false

pop.keyreleased = (key) ->
    print "keyreleased", key

    -- keyreleased events are always called
    element = pop.focused
    if element and element.keyreleased
        return element.keyreleased key

    return false

pop.textinput = (text) ->
    print "textinput", text

    -- textinput events must be on visible elements
    element = pop.focused
    if element and element.textinput and (not element.excludeDraw)
        return element.textinput text

    return false

--TODO rewrite skin system to not rely on knowing internals of elements,
--     instead call functions like setColor and setBackground
-- skins an element (and its children unless depth == true or 0)
--  depth can be an integer for how many levels to go down when skinning
--  defaults to pop.screen and the default skin
pop.skin = (element=pop.screen, skin=pop.skins.default, depth) ->
    if element.background and skin.background
        element.background = skin.background
    if element.color and skin.color
        element.color = skin.color
    if element.font and skin.font
        element.font = skin.font

    unless depth or (depth == 0)
        if depth == tonumber depth
            for i = 1, #element.child
                pop.skin element.child[i], skin, depth - 1
        else
            for i = 1, #element.child
                pop.skin element.child[i], skin, false

pop.debugDraw = (element=pop.screen) ->
    if element.debugDraw
        element\debugDraw!
    else
        graphics.setLineWidth 1
        graphics.setLineColor 0, 0, 0, 100
        graphics.rectangle "fill", element.x, element.y, element.w, element.h
        graphics.setColor 150, 150, 150, 150
        graphics.rectangle "line", element.x, element.y, element.w, element.h
        graphics.setColor 200, 200, 200, 255
        graphics.print ".", element.x, element.y

    for i = 1, #element.child
        pop.debugDraw element.child[i]

pop.printElementTree = (element=pop.screen, depth=0) ->
    cls = element.__class.__name

    if cls == "text"
        cls = cls .. " (\"#{element\getText!\gsub "\n", "\\n"}\")"
    elseif cls == "box"
        bg = element\getBackground!

        if type(bg) == "table"
            bg = "#{bg[1]}, #{bg[2]}, #{bg[3]}, #{bg[4]}"

        cls = cls .. " (#{bg})"

    print string.rep("-", depth) .. " #{cls}"

    for i = 1, #element.child
        pop.printElementStack element.child[i], depth + 1

pop.load!

return pop
