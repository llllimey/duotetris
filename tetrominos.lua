-- tetromino maps
-- first map should be of tetrimino laying on side
Maps ={
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
function Tetromino:new(maps)
    self.map = maps
    self.maxkick = math.ceil(#self.map[1] * 0.5)
    self:findkickmaps()

    self.rotation = 1
    self.row = FIELDSTART+1

    self.speed = 1
    self.time_still = 0
    self.time_next_fall = Falltime*0.2
    self.falldistance = 0
    self.landed = false

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


-- makes tetromino fall 1 unit, if possible
--   returns true if it falls, false if it can't
function Tetromino:fall()
    self:erase()
    -- check to see if it will collide if it moves by 1 in direciton
    local c_row = self.row + 1
    if self:collides_at(c_row, self.col, self.rotation) then
        -- collides, so stop falling:(
        self:mark()
        self.falldistance = 0
        self.landed = true
        -- print("hits ground :(")
        return false
    end

    -- doesn't collide, so fall :))

    -- if it falls far enough, it is no longer landed
    --   this should allow for elevators, but not spinning in place
    if self.falldistance > self.maxkick then
        self.evade_strength = 1
        self.landed = false
    end

    self.row = c_row
    self:mark()
    self.falldistance = self.falldistance + 1
    -- print(self.falldistance)
    -- if self.landed then
    --     print("landed")
    -- else
    --     print("not landed")
    -- end
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
    if self.landed then
        self.time_still = self.time_still - self.time_still * self.evade_strength
        self.evade_strength = self.evade_strength * EVADE_MULTIPLIER
    end
    return true
end


-- updates tetromino.kickmaps with a table of possible kicks
function Tetromino:findkickmaps()
    -- the furthest a tetromino can be kicked to is (maxkick - 1, maxkick) (x, y)
    local maxkick = self.maxkick
    local unsorted = {}
    for x = -maxkick+1, maxkick-1 do
        for y = -maxkick, maxkick do
            local kick = {}
            kick.x = x
            kick.y = y
            kick.distance = math.sqrt(x*x + y*y)
            table.insert(unsorted, kick)
        end
    end

    -- merge sort unsorted kick maps by distance, then y value
    -- start and stop are indexes of the table to start and stop sorting at
    --  this is a bit weird on my brain since tables are pointers
    local function sort(kicks, start, stop)
        local len = (stop - start) + 1
        if len == 1 then
            return kicks
        else
            local midpoint =  math.floor(len * 0.5) + start - 1
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
            for i = start, stop do
                if atemp[1] and btemp[1] then
                    if atemp[1].distance < btemp[1].distance then
                        kicks[i] = atemp[1]
                        table.remove(atemp, 1)
                    elseif atemp[1].distance > btemp[1].distance then
                        kicks[i] = btemp[1]
                        table.remove(btemp, 1)
                    elseif atemp[1].y > btemp[1].y then
                        kicks[i] = atemp[1]
                        table.remove(atemp, 1)
                    elseif atemp[1].y < btemp[1].y then
                        kicks[i] = btemp[1]
                        table.remove(btemp, 1)
                    elseif atemp[1].x > btemp[1].x then
                        kicks[i] = atemp[1]
                        table.remove(atemp, 1)
                    elseif atemp[1].x < btemp[1].x then
                        kicks[i] = btemp[1]
                        table.remove(btemp, 1)
                    end
                else
                    if not atemp[1] then
                        kicks[i] = btemp[1]
                        table.remove(btemp, 1)
                    else
                        kicks[i] = atemp[1]
                        table.remove(atemp, 1)
                    end
                end
            end

            return kicks
        end
    end
    
    self.kickmaps = sort(unsorted, 1, #unsorted)
    for i,v in pairs(self.kickmaps) do
        -- print("("..v.x..", "..v.y..")")
    end
end


-- spins tetromino
function Tetromino:spin(direction)
    local c_rotation = self.rotation
    local rot_mult = 0

    -- see which way it is spinning
    if direction == "cw" then
        rot_mult = 1
    elseif direction == "countercw" then
        rot_mult = -1
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
    -- if it collides, try kicking the piece
    -- try kicking up to a distance of ciel(0.5 piecesize) in one direction,
    --     and that amount -1 in the other
    --        this value is stored in self.kickmax
    local kickmaps = self.kickmaps
    local row = self.row
    local col = self.col
    local height_gained
    for i,v in pairs(kickmaps) do
        local xkick = v.x * x_mult
        local ykick = v.y * y_mult
        if not self:collides_at(row + ykick, col + xkick, c_rotation) then
            -- if it is able to find a working kick
            -- set location to the working kick
            -- print("row: "..self.row.." col: "..self.col.." map: "..self.rotation)
            self.row = row + ykick
            self.col = col + xkick
            self.rotation = c_rotation
            height_gained = ykick
            -- print("row: "..self.row.." col: "..self.col.." map: "..self.rotation)
            break
        end
    end

    -- check if it is now touching the gound
    if self:collides_at(self.row - 1, self.col, self.rotation) then
        self.falldistance = 0
        self.landed = true
        print("landed via spin")
    end

    -- doesn't collide, so move :))
    self:mark()

    -- also, let piece not lock as fast if they're aboutta be locked
    -- but the more times they try to move to evade being locked, the less effective it is
    -- the effectiveness is reset to normal if the piece falls
    if self.landed then
        self.time_still = self.time_still - self.time_still * self.evade_strength
        self.evade_strength = self.evade_strength * KICK_EVADE_MULTIPLIER
    end
    -- print(self.evade_strength)
    return true
end