io.stdout:setvbuf("no")


function love.load()
    FIELDHEIGHT = 25
    FIELDWIDTH = 10
    field = {}

    -- initialize field to blank tiles
    for i=1, #FIELDHEIGHT do
        for j=1, #FIELDWIDTH do
            field[i][j] = " "
        end
    end

    -- colors of tiles
    color = {
        
    }
end


function love.focus(f) focus = f end

function love.update(dt)
    if not focus then return end
end

function love.draw()

end

function love.quit()
    print("the game is done.")
end