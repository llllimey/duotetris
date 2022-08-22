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
        {"o", "o"},
        {"", ""}
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


-- create tetromino class for controllable tetrominos
Tetromino = Object:extend()

-- spawns a tetromino given a type (i, o, j, etc)
--   row is on the y axis, col is on the x axis
function Tetromino:new(type)
    self.map = maps[type]
    self:findkickmaps()
    self.rotation = 1
    self.row = FIELDSTART+1
    self.speed = 1
    self.time_still = 0
    self.time_next_fall = Falltime*0.2
    self.evade_strength = 1
    -- the column a tetrmino spawns on depends on what type it is
    if type == "o" then
        self.col = 6
    else
        self.col = 5
    end

    -- doesn't spawn if there's no space
    if self:collides_at(self.row, self.col, self.rotation) then
        GameOver = true
        print("Game over")
        return false
    end

    -- spawns
    self:mark()
    return true
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


-- checks if the tetromino will collide at a certain location/rotation
--  returns true if it will collide, false if it won't collide
function Tetromino:collides_at(c_row, c_col, c_rotation)
    for i,row in ipairs(self.map[c_rotation]) do
        for j,block in ipairs(row) do
            if block ~= ""  then

                -- check if block is out of bounds
                local y = c_row + i - 1
                local x = c_col + j - 1

                if y < 1 or y > FIELDHEIGHT
                    or x < 1 or x > FIELDWIDTH + 1 then
                    return true
                end

                if Field[y][x] ~= " " then
                    -- if there's tetromino's block is on the same location as an occupied spot on the field
                    --  then there is collision :(((
                    return true
                end
            end
        end
    end
    return false
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
        self.isfalling = false
        return false
    end

    -- doesn't collide, so fall :))
    self.row = c_row
    self:mark()
    print("falls")
    self.isfalling = true
    self.evade_strength = 1
    return true
end

function Tetromino:move(direction)
    -- c_col is new col after moving in specified direction
    local c_col = self.col
    if direction == "right" then
        c_col = self.col + 1
    elseif direction == "left" then
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
        return false
    end

    -- doesn't collide, so move :))
    self.col = c_col
    self:mark()

    -- also, let piece not lock as fast if they're aboutta be locked
    -- but the more times they try to move to evade being locked, the less effective it is
    -- the effectiveness is reset to normal if the piece falls
    if not self.isfalling then
        self.time_still = self.time_still - self.time_still * self.evade_strength
        self.evade_strength = self.evade_strength * EVADE_MULTIPLIER
    end
    return true
end


-- updates tetromino.kickmaps with a table of possible kicks
function Tetromino:findkickmaps()
    -- the furthest a tetromino can be kicked to is (maxkick - 1, maxkick) (x, y)
    local maxkick = math.ceil(#self.map[1] * 0.5)
    local unsorted = {}
    for x = 0, maxkick-1 do
        for y = -x, maxkick do
            local kick = {}
            kick.x = x
            kick.y = y
            kick.distance = math.sqrt(x*x + y*y)
            table.insert(unsorted, kick)
        end
    end

    print("unsorted:")
    for i,v in ipairs(unsorted) do
        print("("..v.x..", "..v.y..") "..v.distance)
    end

    -- merge sort unsorted kick maps by distance, then y value
    -- start and stop are indexes of the table to start and stop sorting at
    --  this is a bit weird on my brain since tables are pointers
    local function sort(kicks, start, stop)
        print(start..stop)
        local len = (stop - start) + 1
        if start - stop == 1 then
            return 
        else
            local midpoint =  math.floor(len * 0.5) + start
            -- sort first half of kicks
            sort(kicks, start, midpoint)
            -- sort second half of kicks
            sort(kicks, midpoint + 1, stop)

            -- merge halves together
            -- store unsorted stuff in a temp
            local atemp = {}
            for i = start, midpoint do
                table.insert(atemp, kicks[i])
            end
            local btemp = {}
            for i = midpoint + 1, stop do
                table.insert(btemp, kicks[i])
            end
            while true do
                
            end

            return
        end
    end
    self.kickmaps = sort(unsorted, 1, #unsorted)
end


-- spins tetromino
function Tetromino:spin(direction)
    local c_rotation = self.rotation
    local rot_mult = 0

    -- see which way it is spinning
    if direction == "cw" then
        rot_mult = -1
    elseif direction == "countercw" then
        rot_mult = 1
    else
        print("Tetromino:spin: direction error")
        return
    end

    -- figure out which map it corresponds with after spinning
    c_rotation = self.rotation + 1 * rot_mult
    if c_rotation > 4 then
        c_rotation = 1
    elseif c_rotation < 1 then
        c_rotation = 4
    end

    -- determine if kicks should be positive/negative compared to defualt (+x, +y) kicks
    local x_mult = rot_mult
    local y_mult = rot_mult
    if c_rotation == 1 or 2 then
        x_mult = -1
    end
    if c_rotation == 1 or 3 then
        y_mult = -1
    end


    self:erase()
    -- check to see if it would collide after moving to new orientation
    -- TODO: if it collides, try kicking the piece
    -- try kicking up to a distance of ciel(0.5 piecesize) in one direction,
    --     and that amount -1 in the other
    --        this value is stored in self.kickmax

    local kickmaps = self.kickmaps
    local row = self.col
    local col = self.col
    local length_kickmaps = #kickmaps
    local kick
    for i = 1, length_kickmaps do
        if not self:collides_at(row + kickmaps[i].y * y_mult, col + kickmaps[i].x * x_mult, c_rotation) then
            -- if it is able to find a working kick
            -- break out of this godforsaken loop
            kick.x = kickmaps[i].x
            kick.y = kickmaps[i].y
            break
        elseif i == length_kickmaps then
            -- if no possible spot is found
            -- then it can't spin :(((
            self:mark()
            return false
        end
    end

    -- doesn't collide, so move :))
    self.col = self.col + kick.x
    self.row = self.row + kick.y
    self.rotation = c_rotation
    print(self.col.." ".. self.row)
    self:mark()

    -- also, let piece not lock as fast if they're aboutta be locked
    -- but the more times they try to move to evade being locked, the less effective it is
    -- the effectiveness is reset to normal if the piece falls
    if not self.isfalling then
        self.time_still = self.time_still - self.time_still * self.evade_strength
        self.evade_strength = self.evade_strength * EVADE_MULTIPLIER
    end
    return true
end