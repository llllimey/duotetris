io.stdout:setvbuf("no")



function love.load()
    tick = require "tick"
    Object = require "classic"
    
    require "tetrominos"
    
    FIELDHEIGHT = 40
    FIELDSTART = FIELDHEIGHT - 20
    FIELDWIDTH = 10
    Field = {}
    -- initialize field to blank area with walls on sides and bottom
    for i=1, FIELDHEIGHT do
        table.insert(Field, {})
        Field[i][1] = "X"
        for j=2, FIELDWIDTH+1 do
            Field[i][j] = " "
        end
        Field[i][FIELDWIDTH+2] = "X"
    end
    local ground = {}
    for i=1, FIELDWIDTH+2 do
        table.insert(ground, "X")
    end
    table.insert(Field, ground)

    -- upcoming tetrominos
    Queue = {}
    Queue.pieces = {"i"}
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
    -- Queue:add_bag()
    -- for i,v in pairs(Queue.pieces) do
    --     io.write(v)
    -- end
    -- print()

    EVADE_MULTIPLIER = 0.8
    KICK_EVADE_MULTIPLIER = 0.9
    LOCKTIME = 0.7
    Falltime = 0.3
end

function love.keypressed(key)
    -- if game is over, allow player to reset game by pressing space
    if GameOver then
        return
    end
    if key == "space" then
        Piece = Tetromino(Queue:next())
        for i,v in pairs(Piece.kickmaps) do
            -- print("("..v.x..", ".. v.y..")")
        end
    end

    if Piece then
        if key == "left" then
            Piece:move("left")
        elseif key == "right" then
            Piece:move("right")
        elseif key == "," then
            Piece:spin("countercw")
        elseif key == "." then
            Piece:spin("cw")
        end
    end
end

function love.focus(f) Focus = f end

function love.update(dt)
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
            Piece = Tetromino(Queue:next())
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
    -- centers and scales everything depending on window size
    -- local width, height = love.window.getDimensions()
    -- local wblock = width 
    local blocksize = 20
    love.graphics.translate(0, -math.floor(blocksize*0.7))

    -- colors of tetrominos (n is blank)
    local colors = {
        X = {0.5, 0.5, 0.5},
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
    for i = FIELDSTART-1, FIELDHEIGHT+1 do
        for j,block in ipairs(Field[i]) do
            love.graphics.setColor(colors[block])
            love.graphics.rectangle("fill", (j - 1)*blocksize, (i - FIELDSTART)*blocksize, blocksize, blocksize)
        end
    end

    -- draw a game over overlay

end

function love.quit()
    print("the game is done.")
end
