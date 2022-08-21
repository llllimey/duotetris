io.stdout:setvbuf("no")



function love.load()
    tick = require "tick"
    Object = require "classic"
    
    require "tetriminos"
    
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


    Piece = Tetrimino("t")
end


function love.focus(f) focus = f end

function love.keypressed(key)

end

function love.update(dt)
    if not focus then return end
    local speed = 1
    -- tetrimino falls
    Piece:fall()
    -- if tetrimino touches ground for long enough
    --  then tetrimino is no longer playable, new tetrimino spawns
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

    -- draws the playable tetrimino
    Piece:draw(blocksize)
end

function love.quit()
    print("the game is done.")
end
