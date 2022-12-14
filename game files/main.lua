io.stdout:setvbuf("no")

Object = require "classic"

require "tetrominos"
require "player" -- also contains row clear function
require "field"

FIELDHEIGHT = 40
FIELDHEIGHTVISIBLE = 20.25
FIELDWIDTH = 13



function love.load()
    love.window.setMode(624, 486)


    -- Tetrofield.field stores everything on the field in the form of letter tiles or
    Tetrofield = Field('tetromino')
    -- Tetrofield.field[40] = {" ", "t", "t", "t", "t", "t", "t", "t", "t", "t", "t", "t", "t"}
    -- Tetrofield.field[39] = {" ", "t", "t", "t", "t", "t", "t", "t", "t", "t", "t", "t", "t"}
    -- Tetrofield.field[38] = {" ", "t", "t", "t", "t", "t", "t", "t", "t", "t", "t", "t", "t"}
    -- Tetrofield.field[37] = {" ", "t", "t", "t", "t", "t", "t", "t", "t", "t", "t", "t", "t"}
    -- Tetrofield.field[36] = {" ", "t", "t", "t", " ", " ", " ", " ", "t", "t", "t", "t", "t"}

    -- Playerfield.field store the location of player tiles as 1 for P1 and 2 for P2
    Playerfield = Field('player')

    -- upcoming tetrominos
    Queue = {}
    Queue.pieces = {}
    -- appends queue with a 7 tetrominos in a random order
    function Queue:add_bag()
        local bag = {"i", "o", "t", "s", "z", "j", "l"}
        for i = #bag, 1, -1 do
            local random = love.math.random(i)
            table.insert(self.pieces, bag[random])
            table.remove(bag, random)
        end
    end
    -- gives the upcoming tetromino
    function Queue:next()
        local p = self.pieces[1]
        table.remove(self.pieces, 1)
        -- also adds another bag to queue if need be
        if #self.pieces < 7 then
            self:add_bag()
        end
        return p
    end

    EVADE_MULTIPLIER = 0.8 -- makes moving to escape piece locking less effectivive over time
    KICK_EVADE_MULTIPLIER = 0.85
    ENHANCEDSPEED = 20 -- how many times faster a piece falls when the down key is held
    Locktime = 0.5 -- how long a piece needs to be still to lock

    Score = nil -- score doesn't exist until game starts
    LINEPOINTMULT = 130 -- how many extra points per extra line cleared
    SPINPOINTMULT = 3 -- multiply the points by this if it's a spin
    Falltime = 1


    Event = {}  -- keeps track of events that need graphics
    Event[1] = {color = {1, 0, 1, 0.08}, mult = 1} -- spin
    Event[2] = {color = {0, 1, 1, 0.1}} -- tetris


    P1 = Player(1)
    P2 = Player(2)

    GameOver = false
    GameStarting = false
    GameStarted = false
end

function love.keypressed(key)
    if key == "g" then Debug:debugkey() end
    -- if game is over, allow player to reset game by pressing space
    if GameOver then
        if key == "space" then
            love.load()
            P2.obstructed = false
            P1.obstructed = false
        end
        return
    end
    -- start the game by pressing space
    if not GameStarting and not GameStarted and key == "space" then
        Begin_count = 0
        Begin_overlay = 0
        GameStarting = true
    end


    -- Controls
    if GameStarted then
        -- P1 movement
        if P1.piece then
            if key == "left" then
                P1.piece:move("left")
            elseif key == "right" then
                P1.piece:move("right")
            elseif key == "," then
                P1.piece:spin("countercw")
            elseif key == "." then
                P1.piece:spin("cw")
            end
            -- P1 hold
            if key == "rshift" and not P1.usedhold then
                if not Held then
                    P1.piece:erase()
                    -- only switch pieces if piece can spawn
                    if not CanSpawn(Maps[Queue.pieces[1]], 1) then
                        P1.piece:mark()
                        return
                    end
                    Held = P1.piece.map
                    P1.piece = Tetromino(Maps[Queue:next()], 1)
                    P1.piece:mark()
                else
                    -- only switch pieces if piece can spawn
                    P1.piece:erase()
                    if not CanSpawn(Held, 1) then
                        P1.piece:mark()
                        return
                    end
                    local temp = Held
                    Held = P1.piece.map
                    P1.piece = Tetromino(temp, 1)
                    P1.piece:mark()
                end
                P1.usedhold = true
            elseif key == "down" then
                P1.piece.time_next_fall = 0
            elseif key == "up" then
                while P1.piece:fall() do end
                P1.piece.time_still = Locktime + 1
            end
        end

        P1:make_ghost()
        P2:make_ghost()

        -- P2 controls
        if P2.piece then
            if key == "a" then
                P2.piece:move("left")
            elseif key == "d" then
                P2.piece:move("right")
            elseif key == "c" then
                P2.piece:spin("countercw")
            elseif key == "v" then
                P2.piece:spin("cw")
            end
            if key == "lshift" and not P2.usedhold then
                if not Held then
                    P2.piece:erase()
                    -- only switch pieces if piece can spawn
                    if not CanSpawn(Maps[Queue.pieces[1]], 2) then
                        P2.piece:mark()
                        return
                    end
                    Held = P2.piece.map
                    P2.piece = Tetromino(Maps[Queue:next()], 2)
                    P2.piece:mark()
                else
                    -- only switch pieces if piece can spawn
                    P2.piece:erase()
                    if not CanSpawn(Held, 2) then
                        P2.piece:mark()
                        return
                    end
                    local temp = Held
                    Held = P2.piece.map
                    P2.piece = Tetromino(temp, 2)
                    P2.piece:mark()
                end
                P2.usedhold = true
            elseif key == "s" then
                P2.piece.time_next_fall = 0
            elseif key == "w" then
                while P2.piece:fall() do end
                P2.piece.time_still = Locktime + 1
            end
        end

        P1:make_ghost()
        P2:make_ghost()
    end
end

function love.focus(f) Focus = f end

function love.update(dt)
    if ForMapOccupiesDo(Tetrofield.field, 1, 1, function(x, y, block)
        if block == 1 or block == 2 then return true end
    end) then Debug:debugkey() end
    -- Debug:printobstructed()
    -- starting sequence
    if GameStarting then
        -- counts to 3 seconds
        Begin_count = Begin_count + dt
        if Begin_count > 1 then
            Begin_count = 0
            Begin_overlay = Begin_overlay + 1
        end
        -- begins game after 3 secondss
        if Begin_overlay == 3 then
            -- add pieces to queue
            Queue:add_bag()
            -- for i,v in pairs(Queue.pieces) do print(v) end
            -- spawn in players
            -- Debug:printobstructed()
            P1:TryNewPiece()
            P2:TryNewPiece()
            
            Score = {points = 0, lines = 0, level = 0, tonextlevel = 10}

            GameStarting = false
            GameStarted = true
        end
        return
    end

    -- don't update if player clicks out of game window
    if not Focus then return end


    -- don't update if game is over
    if GameOver then
        return
    end


    -- update event effects
    for i,v in ipairs(Event) do
        if v.yes == true then
            if not v.time then
                v.time = 0
            end
            -- events lasts for 0.3 seconds
            if v.time > 0.3 then
                v.time = 0
                v.yes = false
                return
            end
            v.time = v.time + dt
        end
    end

    -- update existing pieces
    if P1.piece then
        if love.keyboard.isDown("down") then
            P1.piece.speed = ENHANCEDSPEED
        else
            P1.piece.speed = 1
        end
        P1:update(dt)
    end

    if P2.piece then
        if love.keyboard.isDown("s") then
            P2.piece.speed = ENHANCEDSPEED
        else
            P2.piece.speed = 1
        end
        P2:update(dt)
    end
    -- if both players can't spawn pieces, then the game is over
    if P1.obstructed and not P1.piece and P2.obstructed and not P2.piece then
        print("game over")
        GameOver = true
    end
end

function love.draw()
    local width = love.graphics.getWidth()
    local height = love.graphics.getHeight()

    -- centers and scales everything depending on window size
    local miniblockscale = 0.9
    local border = 6 * miniblockscale
    local display_width_blocks = (FIELDWIDTH + border + border + 2)
    local wblock = width / display_width_blocks
    local hblock = height / (FIELDHEIGHTVISIBLE)

    local blocksize
    if wblock < hblock then
        blocksize = math.floor(wblock)
    else
        blocksize = math.floor(hblock)
    end

    local remainder = width - display_width_blocks * blocksize
    local woffset = math.floor(remainder * 0.5) + border*blocksize + 1

    love.graphics.setBackgroundColor(0.5, 0.5, 0.5)

    -- event effects
    for i,v in pairs(Event) do
        if v.yes then
            love.graphics.setColor(v.color)
            love.graphics.rectangle("fill", 0, 0, width, height)
        end
    end

    -- colors of tetrominos (n is blank)
    local colors = {
        [" "] = {0.8, 0.8, 0.8, 0.75},
        i = {0, 0.94, 0.94},
        o = {0.94, 0.96, 0},
        t = {0.8, 0, 1},
        s = {0.1, 1, 0},
        z = {1, 0, 0.35},
        j = {0, 0.15, 1},
        l = {1, 0.62, 0}
    }


    -- recenter graphics for things in the playing field
    love.graphics.push()
    love.graphics.translate(woffset, 0)
    love.graphics.push()
    love.graphics.translate(0 , -math.floor((FIELDHEIGHT - FIELDHEIGHTVISIBLE)*blocksize) - blocksize)

    -- draws a white background for the playing field
    love.graphics.setColor(1,1,1)
    love.graphics.rectangle("fill", blocksize, blocksize, FIELDWIDTH * blocksize, FIELDHEIGHT * blocksize)

    -- draws the ghosts
    --   they are rendered under the field
    --   since the blank field is slightly transparent, the ghost shows through
    P1:render_ghost(colors, blocksize)
    P2:render_ghost(colors, blocksize)

    -- draws the playing field
    for i,row in ipairs(Tetrofield.field) do
        for j,block in pairs(row) do
            if not colors[block] then print("field draw:") Debug:debugkey() end
            love.graphics.setColor(colors[block])
            love.graphics.rectangle("fill", j*blocksize, i*blocksize, blocksize, blocksize)
        end
    end

    -- gives player blocks a colored border
    local c = {{1, 0.5, 0.5, 0.5}, {0.5, 1, 1, 0.5}}
    -- if ForMapOccupiesDo(Playerfield.field, 1, 1, function(x, y, block)
    --     if not c[block] then print("player border draw") Debug:debugkey() end
    --     love.graphics.setColor(c[block])
    --     love.graphics.rectangle("line", x * blocksize, y * blocksize, blocksize, blocksize)
    -- end) then
    --     -- clear the player field
    --     for i=1, FIELDHEIGHT do
    --         for j=1, FIELDWIDTH do
    --             Playerfield.field[i][j] = " "
    --         end
    --     end
    --     -- re-mark the players onto the field
    --     if P1.piece then P1.piece:playermark() end
    --     if P2.piece then P2.piece:playermark() end
        -- draw the colored borders
        ForMapOccupiesDo(Playerfield.field, 1, 1, function(x, y, block)
            love.graphics.setColor(c[block])
            love.graphics.rectangle("line", x * blocksize, y * blocksize, blocksize, blocksize)
        end)
    -- end

    love.graphics.pop()

    -- draw the score
    love.graphics.setColor(1,1,1)
    love.graphics.print("Level", -90, height -85)
    love.graphics.print("Score", -90, height -45)
    if Score then
        love.graphics.print(tostring(Score.level), -80, height -68)
        love.graphics.print(tostring(Score.points), -80, height -28)
    end

-- draw player time still and time next fall
    -- love.graphics.print("P1", -120, height -250)
    -- love.graphics.print("P2", -120, height -170)
    -- if P1.piece then
    --     local obstruct = "false"
    --     if P1.obstructed then obstruct = "true" end
    --     love.graphics.print("obstructed: "..obstruct, -115, height-230, 0, 0.8,  0.8)
    --     love.graphics.print("time still "..tostring(P1.piece.time_still), -115,height -210, 0, 0.8,  0.8)
    --     love.graphics.print("time next fall "..tostring(P1.piece.time_next_fall), -115,height -190, 0, 0.8,  0.8)
    -- end
    -- if P2.piece then
    --     local obstruct = "false"
    --     if P2.obstructed then obstruct = "true" end
    --     love.graphics.print("obstructed: "..obstruct, -115, height-150, 0, 0.8,  0.8)
    --     love.graphics.print("time still "..tostring(P2.piece.time_still), -115, height-130, 0, 0.8,  0.8)
    --     love.graphics.print("time next fall "..tostring(P2.piece.time_next_fall), -115, height-110, 0, 0.8,  0.8)
    -- end

    -- don't draw anything past this if game isn't started yet
    if not GameStarted and not GameStarting then
        love.graphics.pop()
        return
    end

    local miniblocksize = math.ceil(blocksize * miniblockscale)

    --draw the held tetromino
    if Held then
        -- center to 1 block before the top left corner of the playing field
        --   the 1 block is to account for a barrier
        love.graphics.push()
        love.graphics.translate(0 , 2 * blocksize)

        local width = #Held[1]
        local offset = -width

        -- scale the drawing according to the size of the piece
        local heldblocksize
        if width <= 4 then
            -- drawing settings for normal-sized pieces
            heldblocksize = miniblocksize
        else
            -- drawing settings for large pieces
            heldblocksize = math.floor((border-1) * blocksize / width)
            -- block size is rounded down, but it should at least be 1
            if heldblocksize < 1 then
                heldblocksize = 1
            end
        end

        -- draw the piece
        local rotation = 1
        if Held[5] then rotation = 2 end
        for i,row in ipairs(Held[rotation]) do
            for j, block in pairs(row) do
                if block ~= " " then
                    love.graphics.setColor(colors[block])
                    love.graphics.rectangle("fill", (offset + j - 1) * heldblocksize, (i - 1) * heldblocksize, heldblocksize, heldblocksize)
                end
            end
        end
        love.graphics.pop()
    end

    -- draws next blocks
    love.graphics.translate((FIELDWIDTH + 1) * blocksize, 0)
    love.graphics.setColor(1,1,1)

    local offset = 2
    for i=1, 6 do
        local shape = Queue.pieces[i]
        local hoffset = 0
        if shape == "o" then
            hoffset = 1
        end
        if not colors[shape] then
            break
        end
        love.graphics.setColor(colors[shape])
        local tetromap = Maps[shape][1]
        if shape == "i" then offset = offset - 1 end
        for i,row in pairs(tetromap) do
            offset = offset + 1
            for j,block in ipairs(row) do
                if block ~= " " then
                    love.graphics.rectangle("fill", (j + hoffset) * miniblocksize, offset * miniblocksize, miniblocksize, miniblocksize)
                end
            end
        end
        if shape == "i" then offset = offset - 1 end
        if shape == "o" then offset = offset + 1 end
    end

    
    -- Screen overlay effects
    love.graphics.pop()

    if GameStarting then
        -- the starting animation
        --   (a rectangle overlay that disappears a bit each second)
        offset = math.floor(width * Begin_overlay / 3)

        love.graphics.setColor(0, 0, 100, 0.4)
        love.graphics.rectangle("fill", offset, 0, width, height)
        return
    end

    -- draw a game over overlay
    if GameOver then
        love.graphics.setColor(0.5, 0, 0, 0.4)
        love.graphics.rectangle("fill", 0, 0, width, height)
    end
end

function love.quit()
    -- print("the game is done.")
end




-- some useful print commands for debugging
Debug = {}

-- does these actions when the debug key, g,  is pressed
function Debug:debugkey()
    self:printfields()
    if P1.piece then self:printmaps(P1.piece.map) end
    if P2.piece then self:printmaps(P2.piece.map) end
end

-- prints out the Field and Playerfield
function Debug:printfields(message)
    if message then print(message) end
    for i = 1, #Tetrofield.field do
        for j,block in pairs(Playerfield.field[i]) do
            if block ~= " " then
                io.write(block.." ")
            else
                io.write("??? ")
            end
        end
        io.write("|"..i.. "          ")
        if i < 10 then io.write(" ") end
        for j,block in pairs(Tetrofield.field[i]) do
            if block ~= " " then
                io.write(block.." ")
            else
                io.write("??? ")
            end
        end
        print("|"..i)
    end
    print()
end

function Debug:printbeforefields(field, pfield)
    for i = 1, #field do
        for j,block in pairs(pfield[i]) do
            if block ~= " " then
                io.write(block.." ")
            else
                io.write("??? ")
            end
        end
        io.write("|"..i.. "          ")
        if i < 10 then io.write(" ") end
        for j,block in pairs(field[i]) do
            if block ~= " " then
                io.write(block.." ")
            else
                io.write("??? ")
            end
        end
        print("|"..i)
    end
    print()
end

-- prints all maps from a list of maps
function Debug:printmaps(maps, message)
    if message then print(message) end
    for i=1, 4 do
        print(i.."_________")
        for j,r in pairs(maps[i]) do
            for k,b in pairs(r) do
                if b == " " then b = "???" end
                io.write(b.." ")
            end
            print()
        end
        print()
    end
end
-- prints obstruction status of both players
function Debug:printobstructed()
    local o1 = ""
    local o2 = ""
    if P1.obstructed then o1 = "P1 obstructed " end
    if P2.obstructed then o2 = "P2 obstructed " end
    io.write(o1..o2)
end

function Debug:fielderror(player, message)
    if ForMapOccupiesDo(Tetrofield.field, 1, 1, function(x, y, block)
        if block == 1 or block == 2 then return true end
    end) then
        print('P'..player..' '..message)
        Debug:debugkey()
    else
        return true
    end
end