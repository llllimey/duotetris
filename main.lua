io.stdout:setvbuf("no")



function love.load()
    love.window.setMode(504, 486)

    tick = require "tick"
    Object = require "classic"
    
    require "tetrominos"
    

    FIELDHEIGHT = 40
    FIELDHEIGHTVISIBLE = 20.25
    FIELDWIDTH = 10
    function Start()
        Field = {}
        -- initialize field to blank area with walls on sides and bottom
        for i=1, FIELDHEIGHT do
            table.insert(Field, {})
            for j=1, FIELDWIDTH do
                Field[i][j] = " "
            end
        end

        -- -- print field for debugging
        -- for i = 1, #Field do
        --     for j,block in pairs(Field[i]) do
        --         io.write(block.." ")
        --     end
        --     print("|"..i)
        -- end

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
        Queue:add_bag()

        EVADE_MULTIPLIER = 0.8
        KICK_EVADE_MULTIPLIER = 0.9
        LOCKTIME = 0.7
        Falltime = 0.3
    end
    Start()
    -- for i,v in pairs(Queue.pieces) do
    --     io.write(v)
    -- end
    print()
end

function love.keypressed(key)
    -- if game is over, allow player to reset game by pressing space
    if GameOver then
        if key == "space" then
            Start()
            GameOver = false
        end
        return
    end
    -- start the game by pressing space
    if not GameStarting and not GameStarted and key == "space" then
        Piece = Tetromino(Maps[Queue:next()])
        Begin_count = 0
        Begin_overlay = 0
        GameStarting = true
    end
    if Piece and GameStarted then
        if key == "left" then
            Piece:move("left")
        elseif key == "right" then
            Piece:move("right")
        elseif key == "," then
            Piece:spin("countercw")
        elseif key == "." then
            Piece:spin("cw")
        end
        if key == "m" then
            if not Held then
                Held = Piece.map
                Piece:erase()
                Piece = Tetromino(Maps[Queue:next()])
            else
                local temp = Held
                Held = Piece.map
                Piece:erase()
                Piece = Tetromino(temp)
            end
        end
    end
end

function love.focus(f) Focus = f end

function love.update(dt)
    -- starting sequence
    if GameStarting then
        Begin_count = Begin_count + dt
        if Begin_count > 1 then
            Begin_count = 0
            Begin_overlay = Begin_overlay + 1
        end
        if Begin_overlay == 3 then
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

    tick.update(dt)


    -- update existing piece
    if Piece then
        -- Piece.time_next_fall keeps track of how long until a piece should try to fall again
        -- Piece.time_still keeps track of how long the piece hasn't fallen for
        -- Piece locks if it is still for more than 0.5 seconds
        if Piece.time_still > LOCKTIME then
            Piece = Tetromino(Maps[Queue:next()])
        else
            Piece.time_still = Piece.time_still + dt
            if not Piece.landed then
                Piece.time_still = 0
            end
            if Piece.time_next_fall > 0 then
                Piece.time_next_fall = Piece.time_next_fall - Piece.speed * dt
            -- if it is time to fall, then try falling. If it falls, then timers need to reset to account for movement
            elseif Piece:fall() then
                Piece.time_next_fall = Falltime
            end
        end
    end
end

function love.draw()
    local width = love.graphics.getWidth()
    local height = love.graphics.getHeight()

    -- centers and scales everything depending on window size
    local miniblockscale = 0.9
    local border = 5 * miniblockscale
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

    love.graphics.push()
    love.graphics.translate(woffset, 0)
    love.graphics.push()
    love.graphics.translate(0 , -math.floor((FIELDHEIGHT - FIELDHEIGHTVISIBLE)*blocksize))
    love.graphics.setBackgroundColor(0.5, 0.5, 0.5)

    -- colors of tetrominos (n is blank)
    local colors = {
        [" "] = {1, 1, 1},
        i = {0, 0.94, 0.94},
        o = {0.94, 0.96, 0},
        t = {0.8, 0, 1},
        s = {0.15, 1, 0},
        z = {255, 0, 0.35},
        j = {0, 0.15, 1},
        l = {1, 0.62, 0}
    }

    -- draws the playing field
    for i,row in ipairs(Field) do
        for j,block in pairs(row) do
            love.graphics.setColor(colors[block])
            love.graphics.rectangle("fill", j * blocksize, (i - 1)*blocksize, blocksize, blocksize)
        end
    end
    love.graphics.pop()

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
        love.graphics.translate(0 , blocksize)

        local width = #Held[1]
        local offset = -width

        -- scale the drawing according to the size of the piece
        local heldblocksize
        if width <= 4 then
            -- drawing settings for normal-sized pieces
            heldblocksize = miniblocksize
        else
            -- drawing settings for large pieces
            heldblocksize = math.floor(4 / width)
            -- block size is rounded down, but it should at least be 1
            if heldblocksize < 1 then
                heldblocksize = 1
            end
        end

        -- draw the piece
        for i,row in ipairs(Held[1]) do
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
    end

    
    -- start and stop overlays

    love.graphics.pop()

    if GameStarting then
        -- the starting animation
        --   (a rectangle overlay that disappears a bit each second)
        offset = math.floor(width * Begin_overlay / 3)

        love.graphics.setColor(0, 0, 100, 0.5)
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
    print("the game is done.")
end
