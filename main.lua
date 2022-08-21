io.stdout:setvbuf("no")


function love.load()
    Object = require "classic"
    require "tetriminos"

    FIELDHEIGHT = 20
    FIELDWIDTH = 10
    Field = {}

    -- initialize field to blank tiles
    for i=1, FIELDHEIGHT do
        table.insert(Field, {})
        for j=1, FIELDWIDTH do
            Field[i][j] = " "
        end
    end
end


function love.focus(f) focus = f end

function love.keypressed(key)
    if key == "t" then
        Piece = Tetrimino("t")
        Piece:exist()
    end
end

function love.update(dt)
    if not focus then return end
    -- if there is space, tetrimino falls
    -- if tetrimino touches ground for long enough
    --  then tetrimino is no longer playable, new tetrimino spawns
end

function love.draw()
    -- draws the playing field
    local blocksize = 20
    for i,row in ipairs(Field) do
        for j,block in ipairs(row) do
            -- colors of tetriminos (n is blank)
            local colors = {
                [" "] = {1, 1, 1},
                i = {0, 0.94, 0.94},
                o = {0.94, 0.96, 0},
                t = {0.72, 0, 1},
                s = {0.15, 1, 0},
                z = {255, 0, 0.35},
                j = {0, 0.15, 1},
                l = {1, 0.62, 0}
            }  
            love.graphics.setColor(colors[block])
            love.graphics.rectangle("fill", j*blocksize, i*blocksize, blocksize, blocksize)
        end
    end
end

function love.quit()
    print("the game is done.")
end