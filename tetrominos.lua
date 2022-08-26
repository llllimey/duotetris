-- tetromino maps
-- first map should be of tetrimino laying on side
-- maps are always squares
Maps ={
    i = {{
        {" ", " ", " ", " "},
        {"i", "i", "i", "i"},
        {" ", " ", " ", " "},
        {" ", " ", " ", " "}
    }, {
        {" ", " ", "i", " "},
        {" ", " ", "i", " "},
        {" ", " ", "i", " "},
        {" ", " ", "i", " "}
    }, {
        {" ", " ", " ", " "},
        {" ", " ", " ", " "},
        {"i", "i", "i", "i"},
        {" ", " ", " ", " "}
    }, {
        {" ", "i", " ", " "},
        {" ", "i", " ", " "},
        {" ", "i", " ", " "},
        {" ", "i", " ", " "}
    }
    },

    j = {{
        {"j", " ", " "},
        {"j", "j", "j"},
        {" ", " ", " "}
    }, {
        {" ", "j", "j"},
        {" ", "j", " "},
        {" ", "j", " "},
    }, {
        {" ", " ", " "},
        {"j", "j", "j"},
        {" ", " ", "j"}
    }, {
        {" ", "j", " "},
        {" ", "j", " "},
        {"j", "j", " "}
    }
    },

    l = {{
        {" ", " ", "l"},
        {"l", "l", "l"},
        {" ", " ", " "}
    }, {
        {" ", "l", " "},
        {" ", "l", " "},
        {" ", "l", "l"},
    }, {
        {" ", " ", " "},
        {"l", "l", "l"},
        {"l", " ", " "}
    }, {
        {"l", "l", " "},
        {" ", "l", " "},
        {" ", "l", " "}
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
        {" ", "s", "s"},
        {"s", "s", " "},
        {" ", " ", " "}
    }, {
        {" ", "s", " "},
        {" ", "s", "s"},
        {" ", " ", "s"},
    }, {
        {" ", " ", " "},
        {" ", "s", "s"},
        {"s", "s", " "}
    }, {
        {"s", " ", " "},
        {"s", "s", " "},
        {" ", "s", " "}
    }
    },

    t = {{
        {" ", "t", " "},
        {"t", "t", "t"},
        {" ", " ", " "}
    }, {
        {" ", "t", " "},
        {" ", "t", "t"},
        {" ", "t", " "},
    }, {
        {" ", " ", " "},
        {"t", "t", "t"},
        {" ", "t", " "}
    }, {
        {" ", "t", " "},
        {"t", "t", " "},
        {" ", "t", " "}
    }
    },

    z = {{
        {"z", "z", " "},
        {" ", "z", "z"},
        {" ", " ", " "}
    }, {
        {" ", " ", "z"},
        {" ", "z", "z"},
        {" ", "z", " "},
    }, {
        {" ", " ", " "},
        {"z", "z", " "},
        {" ", "z", "z"}
    }, {
        {" ", "z", " "},
        {"z", "z", " "},
        {"z", " ", " "}
    }}
}


-- create tetromino class for controllable tetrominos
Tetromino = Object:extend()

-- spawns a tetromino given a type (i, o, j, etc)
--   row is on the y axis, col is on the x axis
function Tetromino:new(maps, player)
    self.map = maps
    local width = #self.map[1]
    self.width = width
    self.maxkick = math.ceil(width * 0.5)
    self:findkickmaps()
    self.p = player -- which player the tetromino belongs to

    self.marked = false

    self.rotation = 1

    self.speed = 1
    self.time_still = 0
    self.time_next_fall = Falltime
    self.falldistance = 0
    self.landed = false

    self.evade_strength = 1


    -- very wide pieces spawn sideways
    if width > FIELDWIDTH then
        width = maps[5].short
        self.rotation = 2
    end

    -- tetriminos spawn on the top of the screen
    local whitespace = 0
    for i,row in pairs(self.map[1]) do
        -- calculate the amount of blank rows on top of the tetro map
        local blanks = 0
        for j, block in pairs(row) do
            if block == " " then
                blanks = blanks + 1
            end
        end
        if blanks == width then
            whitespace = whitespace + 1
        else
            break
        end
    end

    self.row = math.ceil(FIELDHEIGHT - FIELDHEIGHTVISIBLE + 1) - whitespace

    -- tetrominos spawn on the center of their side, erring away from the middlex
    local offset
    local col
    local pdirection
    if player == 1 then
        pdirection = -1
        offset = FIELDWIDTH * 1.5 - width
        col = math.ceil(offset * 0.5) + 1
    elseif player == 2 then
        pdirection = 1
        offset = FIELDWIDTH * 0.5 - width
        col = math.floor(offset * 0.5) + 1
    else
        return
    end
    self.col = col

    if not self.col then print("tetro:new no col") end
    if not self.row then print("tetro:new no row") end
    if not self.row or not self.col then return end

    -- if the normal spawn location is unavailable, kick to the nearest spot
    -- if the normal range of kicks doesn't work, try moving to the left/right and try again

    -- how far the piece is to the other edge
    local to_edge = col
    if player == 2 then
        to_edge = FIELDWIDTH - (col + (width))
    end

    self.spawned = false

    -- kicks piece, moving towards edge if it doesn't work
    -- returns true if it succeeds in kicking the piece, nothing otherwise
    local function spawnkick(rotation)
        for i=1, to_edge do
            if self:spin(rotation) then
                -- finds the lowest tile of the piece
                local lowesttile = 0
                ForMapOccupiesDo(self.map[self.rotation], self.col, self.row, function(x, y)
                    if y > lowesttile then lowesttile = y end
                end)
                -- if the lowest tile is above the field, the locatiion is invalid
                -- because the piece cannot be seen by anyone playing the game
                if lowesttile < math.ceil(FIELDHEIGHT - FIELDHEIGHTVISIBLE) then return end
                self.spawned = true
                self.obstructed = false
                
                if not self.col then print("spawnkick: no col") end
                if not self.row then print("spawnkick: no row") end
                return true
            end
            self.col = self.col + pdirection
        end
    end

    -- try kicking with no rotation, and if that doesn't work, kick with rotation
    if spawnkick("kick "..player) then return end
    if spawnkick("countercw") then return end

    -- if both kicks fail, then piece is obstructed
    self.obstructed = true
end



-- does a function(x, y, block) for block occupied by a map,
-- (x, y) being the coordinates of a tile on the field, block being what is at that tile.
-- can return true if f() returns true, returns nothing otherwise.
-- useful so i don't have to rewrite the loop for iterating through the block
function ForMapOccupiesDo(map, col, row, f)
    for i,r in pairs(map) do
        for j,block in pairs(r) do
            if block ~= " " then
                -- print(j)
                local y = row + i - 1
                local x = col + j - 1
                if f(x, y, block) then return true
                end
            end
        end
    end
end

-- removes tetromino from both fields
--  use together with mark() to ensure tetromino doesn't leave a ghost behind
function Tetromino:erase()
    ForMapOccupiesDo(self.map[self.rotation], self.col, self.row, function(x, y)
        Field[y][x] = " "
        Playerfield[y][x] = " "
    end)
end

-- marks tetromino on both fields
--   does not check for collision
function Tetromino:mark()
    if not self.row or not self.col then
        print("mark: no row or col")
    end
    ForMapOccupiesDo(self.map[self.rotation], self.col, self.row, function(x, y, block)
        -- print(block)
        Field[y][x] = block
        Playerfield[y][x] = self.p
    end)
end

-- only erases tetro from the player field
--   used when piece locks
function Tetromino:playererase()
    ForMapOccupiesDo(self.map[self.rotation], self.col, self.row, function(x, y)
        Playerfield[y][x] = " "
    end)
end

-- checks if the tetromino will collide at a certain location/rotation
--  returns true if it will collide, false if it won't collide
function Tetromino:collides_at(c_row, c_col, c_rotation)
    if ForMapOccupiesDo(self.map[c_rotation], c_col, c_row, function (x, y)
        if not Field[y] or Field[y][x] ~= " " then
            return true
        end
    end) then return true else return false end
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
    self.justspun = false
    self.falldistance = self.falldistance + 1
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
    self.justspun = false

    -- also, let piece not lock as fast if they're aboutta be locked
    -- but the more times they try to move to evade being locked, the less effective it is
    -- the effectiveness is reset to normal if the piece falls
    if self.landed then
        self.time_still = self.time_still * (1 - self.evade_strength)
        self.evade_strength = self.evade_strength * EVADE_MULTIPLIER
    end
    return true
end


-- updates tetromino.kickmaps with a table of possible kicks
function Tetromino:findkickmaps()
    -- the furthest a tetromino can be kicked to is (maxkick - 1, maxkick) (x, y)
    local maxkick = self.maxkick
    local unsorted = {}
    for x = -maxkick, maxkick do
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
                    elseif atemp[1].y < btemp[1].y then
                        kicks[i] = atemp[1]
                        table.remove(atemp, 1)
                    elseif atemp[1].y > btemp[1].y then
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
    elseif direction ~= "kick 1" and direction ~= "kick 2" then
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

    -- special cases for kicks without specified rotation
    if rot_mult == 0 then
        c_rotation = self.rotation
        y_mult = 1
        if direction == "kick 1" then
            x_mult = -1
        elseif direction == "kick 2" then
            x_mult = 1
        end
    end

    if self.spawned then self:erase() end
    -- check to see if it would collide after moving to new orientation
    -- if it collides, try kicking the piece
    -- try kicking up to a distance of ciel(0.5 piecesize) in one direction,
    --     and that amount -1 in the other
    --        this value is stored in self.kickmax
    local kickmaps = self.kickmaps
    local row = self.row
    local col = self.col
    for i,v in pairs(kickmaps) do
        local xkick = v.x * x_mult
        local ykick = v.y * y_mult
        if not self:collides_at(row + ykick, col + xkick, c_rotation) then
            -- if it is able to find a working kick
            -- set location to the working kick
            self.row = row + ykick
            self.col = col + xkick
            self.rotation = c_rotation


            -- if here from trying to spawn, return true for it is able to be kicked
            if not self.spawned then
                return true
            end
            break
        end
    end

    -- check if it is now touching the gound
    if self:collides_at(self.row - 1, self.col, self.rotation) then
        self.falldistance = 0
        self.landed = true
    end

    -- if here from trying to spawn, return false for it is not able to be kicked
    if not self.spawned then
        return false
    end

    -- doesn't collide, so move :))
    self:mark()
    self.justspun = true

    -- also, let piece not lock as fast if they're aboutta be locked
    -- but the more times they try to move to evade being locked, the less effective it is
    -- the effectiveness is reset to normal if the piece falls
    if self.landed then
        self.time_still = self.time_still * (1 - self.evade_strength)
        self.evade_strength = self.evade_strength * KICK_EVADE_MULTIPLIER
    end
    return true
end