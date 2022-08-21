-- tetrimino maps
local I = {{
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
}

local J = {{
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
}

local L = {{
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
}

local O = {{
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
}

local S = {{
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
}

local T = {{
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
}

local Z = {{
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
}
}


Tetrimino = Object:extend()

-- spawns a tetrimino given a type (i, o, j, etc)
function Tetrimino:new(type)
    self.row = 1
    self.rotation = 1
    if type == "i" then
        self.col = 3
        self.map = I
    elseif type == "o" then
        self.col = 5
        self.map = O
    else
        self.col = 4
        if type == "j" then
            self.map = J
        elseif type == "l" then
            self.map = L
        elseif type == "t" then
            self.map = T
        elseif type == "s" then
            self.map = S
        elseif type == "z" then
            self.map = Z
        end
    end
end

function Tetrimino:exist()
    --places a tetrimino on the playing field
    for i,row in ipairs(self.map[self.rotation]) do
        for j,block in ipairs(row) do
            if block ~= "" then
                Field[self.row + i - 1][self.col + j - 1] = block
            end
        end
    end
end
