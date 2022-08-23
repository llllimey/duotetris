Player = Object:extend()

function Player:new(n)
    self.n =  n
end

-- updates tetromino to fall or lock
function Player:update(dt)
    if Player.obstructed then
        -- if the player is obstructed, keep trying to spawn
        self:TryNewPiece()
        return
    end
    -- self.piece.time_next_fall keeps track of how long until a piece should try to fall again
    -- self.piece.time_still keeps track of how long the piece hasn't fallen for
    -- self.piece locks if it is still for more than Locktime seconds
    if self.piece.time_still > Locktime then
        local rot = self.piece.rotation
        local row = self.piece.row
        local col = self.piece.col

        self.piece:erase() -- always gotta erase before checking collisions
        -- don't lock if the piece can still fall downwards
        if not self.piece:collides_at(row + 1, col, rot) then
            self.piece:mark()
            return
        end

        -- from henceforth, the piece is locked

        -- check if piece landed by spinning
        if      self.piece:collides_at(row - 1, col, rot) -- couldn't arrive by falling
            and self.piece:collides_at(row, col + 1, rot) -- couldn't arrive by moving left
            and self.piece:collides_at(row, col - 1, rot) -- couldn't arrive by moving right
            then
            Event[1].yes = true
            Event[1].mult = SPINPOINTMULT
            print("spin")
        end
        self.piece:mark()

        -- if piece locks, then player is able to use hold pieces again
        self.usedhold = false

        self.piece = nil   -- player has no piece

        -- if it locks on to a player, then add the map to that player
        if self:onplayer() then
            self:givemap()
        else
            -- if it isn't locked on to a player, then it must be on the ground
            -- so, try clearing rows
            TryRowClear()
        end
            
        self:TryNewPiece() -- try to give player a new piece
    else
        self.piece.time_still = self.piece.time_still + dt
        if not self.piece.landed then
            self.piece.time_still = 0
        end
        if self.piece.time_next_fall > 0 then
            self.piece.time_next_fall = self.piece.time_next_fall - self.piece.speed * dt
        -- if it is time to fall, then try falling. If it falls, then timers need to reset to account for movement
        elseif self.piece:fall() then
            self.piece.time_next_fall = Falltime

            -- also gotta update the ghosts
            P1:make_ghost()
            P2:make_ghost()
        end
    end
end


-- checks if a player has landed on the other player
function Player:onplayer()
end

-- gives its map to the other player
function Player:givemap(dimension)
end


function Player:TryNewPiece()
    -- checks if new piece can spawn. If it can't, then don't do anything
    if not CanSpawn(Maps[Queue.pieces[1]], self.n) then
        Player.obstruced = true
        return
    end

    -- new piece spawns 
    Player.obstructed = false
    self.piece:playererase()
    self.piece = Tetromino(Maps[Queue:next()], self.n)
    self.piece:mark()
    -- don't forget to make a ghost
    self:make_ghost()
end

-- checks to see if a map of a tetromino can spawn
function CanSpawn(map, player)
    local check = Tetromino(map, player)
    if check.obstructed then
        return false
    end
    return true
end

-- clears rows if they are filled
-- if the other player is in the row, they get removed with it
function TryRowClear(otherp)
    local fullrows = {}
    for i = 1, FIELDHEIGHT do
        -- if a row is full of blocks, then keep track of it
        local count = FIELDWIDTH
        for j,block in pairs(Field[i]) do
            if block ~= " " then
                count = count - 1
            end
        end
        if count == 0 then
            table.insert(fullrows, i)
        end
    end

    local linescleared = #fullrows
    -- if there are no full rows, then don't do anything
    if linescleared < 1 then
        return
    end

    -- make an empty row for adding to the field
    local emptyrow = {}
    for i = 1, FIELDWIDTH do
        table.insert(emptyrow, " ")
    end

    -- remove full rows and add new rows for each one removed
    for i,v in pairs(fullrows) do
        -- print(v)
        table.remove(Field, v)
        table.insert(Field, 1, emptyrow)
    end

    -- if 4+ lines are cleared, then do a fun tetris effect
    if linescleared > 3 then
        Event[2].yes = true
        print("tetris")
    end

    -- check for full clear
    local fullclear_mult = 8
    for i,v in pairs(Field) do
        for j,block in pairs(v) do
            if block ~= " " then
                fullclear_mult = 1
            end
        end
    end
    -- effect for full clear (it's the same effect as tetris)
    if fullclear_mult == 8 then
        Event[2].yes = true
        print("full clear")
    end

    -- calculate points for lines (no multipliers yet), more lines more points/line
    local lines_points = 100 
    for i=1, linescleared-1 do
        lines_points = lines_points + LINEPOINTMULT* i
    end
    -- calculate total points (includes multipliers)
    Score.points = Score.points + (lines_points * (Score.level + 1) * Event[1].mult * fullclear_mult)

    -- resets multiplier for spins
    Event[1].mult = 1

    -- keep track of lines cleared
    Score.lines = Score.lines + linescleared

    -- keep track of level and falltime
    while linescleared > 0 do
        print(Score.tonextlevel, linescleared)
        Score.tonextlevel = Score.tonextlevel - linescleared
        print(Score.tonextlevel)
        if Score.tonextlevel <= 0 then
            print(Score.tonextlevel)
            linescleared = -Score.tonextlevel
            Score.level = Score.level + 1
            Score.tonextlevel = (Score.level + 1) * 10
            if Score.level < 20 then
                Falltime = Falltime * 0.8
            elseif Score.level < 30 then
                Locktime = Locktime * 0.9
            end
        else
            linescleared = 0
        end
    end

    print(Score.points, Score.lines, Score.level)
end


-- make a ghost for a player (shows where their piece falls)
--  ghost will be updated when piece spawns or moves
function Player:make_ghost()
    -- erase piece so it doesn't interfere with ghost
    self.piece:erase()

    local ghost = {}
    ghost.map = self.piece.map[self.piece.rotation]
    ghost.y = self.piece.row
    ghost.x = self.piece.col
    local function collides_at(c_row, c_col, map)
        for i,row in ipairs(map) do
            for j,block in ipairs(row) do
                if block ~= " "  then
                    local y = c_row + i - 1
                    local x = c_col + j - 1
                    if not Field[y] or Field[y][x] ~= " " then
                        -- if the tile the tetrimino is on isn't empty
                        --  then there is collision :(((
                        return true
                    end
                end
            end
        end
        return false
    end

    while not collides_at(ghost.y + 1, ghost.x, ghost.map) do
        ghost.y = ghost.y + 1
    end

    -- the ghost is complete. return it.
    self.ghost = ghost
    -- print(self.piece.map[1][2][2], ghost.x, ghost.y)

    -- mark piece now that ghost is found
    self.piece:mark()
end

-- renders a ghost
function Player:render_ghost(colors, blocksize)
    if self.piece and self.ghost then
        for i,row in pairs(self.ghost.map) do
            for j, block in pairs(row) do
                if block ~= " " then
                    love.graphics.setColor(colors[block])
                    local x = (self.ghost.x + j - 1) * blocksize
                    local y = (self.ghost.y + i - 1) * blocksize
                    love.graphics.rectangle("fill", x, y, blocksize, blocksize)
                    
                    if Field[self.ghost.y + i - 1][self.ghost.x + j - 1] ~= " " then
                        -- print(self.ghost.x, self.ghost.y)
                    end
                end
            end
        end
    end
end