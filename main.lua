io.stdout:setvbuf("no")



function love.load()
    tick = require "tick"
    Object = require "classic"
    
    require "tetrominos"
    
    FIELDHEIGHT = 20
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
        next = self.pieces[1]
        table.remove(self.pieces, 1)
        -- also adds another bag to queue if need be
        if #self.pieces < 7 then
            self:add_bag()
        end
        return next
    end
    Queue:add_bag()

    Speed = 0.3
end


function love.focus(f) focus = f end

function love.keypressed(key)
    if key == "space" then
        Piece = Tetromino(Queue:next())
    end

    if Piece then
        if key == "left" then
            Piece:move("left")
        elseif key == "right" then
            Piece:move("right")
        end
    end
end

function love.update(dt)
    if not focus then return end
    tick.update(dt)

    -- update existing piece
    if Piece then
        -- if tetrimino falls to ground, spawn next one
        if Piece.isfallen then
            Piece = Tetromino(Queue:next())
        end
    end
end

function love.draw()
    -- draws the playing field
    local blocksize = 20
    for i,row in ipairs(Field) do
        for j,block in ipairs(row) do
            love.graphics.setColor(Colors[block])
            love.graphics.rectangle("fill", (j - 1)*blocksize, (i - 1)*blocksize, blocksize, blocksize)
        end
    end
end

function love.quit()
    print("the game is done.")
end
