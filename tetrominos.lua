-- tetromino maps
-- first map should be of tetrimino laying on side
local maps ={
    i = {{
        {"", "", "", ""},
        {"i", "i", "i", "i"},
        {"", "", "", ""},
        {"", "", "", ""}
    }, {
        {"", "", "i", ""},
        {"", "", "i", ""},
        {"", "", "i", ""},
        {"", "", "i", ""}
    }, {
        {"", "", "", ""},
        {"", "", "", ""},
        {"i", "i", "i", "i"},
        {"", "", "", ""}
    }, {
        {"", "i", "", ""},
        {"", "i", "", ""},
        {"", "i", "", ""},
        {"", "i", "", ""}
    }
    },

    j = {{
        {"j", "", ""},
        {"j", "j", "j"},
        {"", "", ""}
    }, {
        {"", "j", "j"},
        {"", "j", ""},
        {"", "j", ""},
    }, {
        {"", "", ""},
        {"j", "j", "j"},
        {"", "", "j"}
    }, {
        {"", "j", ""},
        {"", "j", ""},
        {"j", "j", ""}
    }
    },

    l = {{
        {"", "", "l"},
        {"l", "l", "l"},
        {"", "", ""}
    }, {
        {"", "l", ""},
        {"", "l", ""},
        {"", "l", "l"},
    }, {
        {"", "", ""},
        {"l", "l", "l"},
        {"l", "", ""}
    }, {
        {"l", "l", ""},
        {"", "l", ""},
        {"", "l", ""}
    }
    },

    o = {{
        {"o", "o"},
        {"o", "o"}
    }, {
        {"o", "o"},
        {"o", "o"}
    }, {
        {"o", "o"},
        {"o", "o"}
    }, {
        {"o", "o"},
        {"o", "o"}
    }
    },

    s = {{
        {"", "s", "s"},
        {"s", "s", ""},
        {"", "", ""}
    }, {
        {"", "s", ""},
        {"", "s", "s"},
        {"", "", "s"},
    }, {
        {"", "", ""},
        {"", "s", "s"},
        {"s", "s", ""}
    }, {
        {"s", "", ""},
        {"s", "s", ""},
        {"", "s", ""}
    }
    },

    t = {{
        {"", "t", ""},
        {"t", "t", "t"},
        {"", "", ""}
    }, {
        {"", "t", ""},
        {"", "t", "t"},
        {"", "t", ""},
    }, {
        {"", "", ""},
        {"t", "t", "t"},
        {"", "t", ""}
    }, {
        {"", "t", ""},
        {"t", "t", ""},
        {"", "t", ""}
    }
    },

    z = {{
        {"z", "z", ""},
        {"", "z", "z"},
        {"", "", ""}
    }, {
        {"", "", "z"},
        {"", "z", "z"},
        {"", "z", ""},
    }, {
        {"", "", ""},
        {"z", "z", ""},
        {"", "z", "z"}
    }, {
        {"", "z", ""},
        {"z", "z", ""},
        {"z", "", ""}
    }}
}

-- colors of tetrominos (n is blank)
Colors = {
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


-- debug code
-- for i,row in ipairs(Field) do
--     for j,block in ipairs(row) do
--         io.write("X")
--     end
--     print()
-- end


-- create tetromino class for controllable tetrominos
Tetromino = Object:extend()

-- spawns a tetromino given a type (i, o, j, etc)
--   row is on the y axis, col is on the x axis
function Tetromino:new(type)
    self.map = maps[type]
    self.color = Colors[type]
    self.rotation = 1
    self.row = 1
    self.speed = 1
    -- the column a tetrmino spawns on depends on what type it is
    if type == "o" then
        self.col = 6
    else
        self.col = 5
    end

    self:mark()
    self.falling = tick.recur(function() self:fall() end , Speed*self.speed)
end


-- checks if the tetromino will collide at a certain location/rotation
--  returns true if it will collide, false if it won't collide
function Tetromino:collides_at(c_row, c_col, c_rotation)
    -- if c_row < 1 or c_row + #self.map[self.rotation]-1 > FIELDHEIGHT or
    --    c_col < 1 or c_col + #self.map[self.rotation][1]-1> FIELDWIDTH or
    --    c_rotation < 1 or c_rotation > 4 then
    --     print(c_col)
    --     print("error using Tetromino:collides_at")
    --     return true
    -- end
    for i,row in ipairs(self.map[c_rotation]) do
        for j,block in ipairs(row) do
            if block ~= ""  and Field[c_row + i - 1][c_col + j - 1] ~= " " then
                -- if there's tetromino's block is on the same location as an occupied spot on the field
                --  then there is collision :(((
                return true
            end
        end
    end
    return false
end

-- removes tetromino from the field
--  use together with mark() to ensure tetromino doesn't leave a ghost behind
function Tetromino:erase()
    for i,row in ipairs(self.map[self.rotation]) do
        for j,block in ipairs(row) do
            -- set field block to empty wherever a tetromino is
            if block ~= "" then
                Field[self.row + i - 1][self.col + j - 1] = " "
            end
        end
    end
end


-- marks tetromino on the field
--   does not check for collision
function Tetromino:mark()
    for i,row in ipairs(self.map[self.rotation]) do
        for j,block in ipairs(row) do
            -- set field block to tetromino wherever tetromino is
            if block ~= "" then
                Field[self.row + i - 1][self.col + j - 1] = block
                -- io.write("Set!")
            end
        end
    end
end

-- moves tetromino by 1 unit if possible
--   returns true if it falls, false if it can't
function Tetromino:fall()
    self:erase()
    -- check to see if it will collide if it moves by 1 in direciton
    local c_row = self.row + 1
    if self:collides_at(c_row, self.col, self.rotation) then
        -- collides, so stop falling:(
        self:mark()
        print("collides :(")
        self.falling: stop()
        self.isfallen = true
        return false
    end

    -- doesn't collide, so fall :))
    self.row = c_row
    self:mark()
    print("moves :)")
    return true
end

function Tetromino:move(dircetion)
    -- c_col is new col after moving in specified direction
    print("self"..self.col)
    local c_col = self.col
    if dircetion == "right" then
        c_col = self.col + 1
    elseif dircetion == "left" then
        c_col = self.col - 1
    else
        print("Tetromino:move: direction error")
        return
    end
    
    self:erase()
    -- check to see if it would collide after moving to new col
    if self:collides_at(self.row, c_col, self.rotation) then
        -- collides :(
        self:mark()
        print("collides :(")
        return false
    end

    -- doesn't collide, so move :))
    self.col = c_col
    self:mark()
    print("moves :)")
    return true
end