function love.conf(t)
    t.accelerometerjoystick = false     -- Enable the accelerometer on iOS and Android by exposing it as a Joystick (boolean)

    t.window.title = "duotetris"         -- The window title (string)
    t.window.icon = "icon.png"                 -- Filepath to an image to use as the window's icon (string)
    t.window.width = 624                -- The window width (number)
    t.window.height = 486               -- The window height (number)

    t.modules.audio = false              -- Enable the audio module (boolean)
    t.modules.joystick = false           -- Enable the joystick module (boolean)
    t.modules.physics = false            -- Enable the physics module (boolean)
    t.modules.sound = false              -- Enable the sound module (boolean)
    t.modules.video = false             -- Enable the video module (boolean)
end