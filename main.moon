-- Jacob Cazabon 2017


-- Maximum movement force magnitude
MaxMoveForce = 300

-- Maximum cart x-velocity
MaxVelx = 500

-- Maximum balanced pole angle, in radians
MaxAngle = math.rad(36)

-- Maximum pole angular velocity
MaxAvel = 2

-- World objects
world = nil
gnd = {} -- Ground
wl = {} -- Left wall
wr = {} -- Right wall
cart = {} -- Cart
p1 = {} -- First (short) pole
p2 = {} -- Second (long) pole
p1j = {} -- Joint between pole 1 & cart
p2j = {} -- Joint between pole 2 & cart

-- Total active time elapsed
t = 0

-- Has the cart moved? (0 = no, 1 = yes)
moved = 0


love.load = ->

    -- Get window dimensions
    wW, wH = love.graphics.getDimensions!

    -- Set ratio 1m = 128px
    love.physics.setMeter 128

    -- Create world
    gX = 0 -- X-gravity
    gY = 9.81 * love.physics.getMeter! -- Y-gravity
    world = love.physics.newWorld gX, gY, true

    -- Create ground
    gnd = {}
    gndW, gndH = wW * 2, wH / 8 -- Ground width & height
    gndX, gndY = wW / 2, wH - gndH / 2 -- Centerpoint x & y
    gnd.body = love.physics.newBody world, gndX, gndY, "static"
    gnd.shape = love.physics.newRectangleShape gndW, gndH
    gnd.fixture = love.physics.newFixture gnd.body, gnd.shape

    -- Create left wall
    wl = {}
    wlW, wlH = 2, wH -- Wall width & height
    wlX, wlY = 0, wH / 2 -- Centerpoint x & y
    wl.body = love.physics.newBody world, wlX, wlY, "static"
    wl.shape = love.physics.newRectangleShape wlW, wlH
    wl.fixture = with love.physics.newFixture wl.body, wl.shape
        \setGroupIndex -1 -- Disable collision for fixtures in this group

    -- Create right wall
    wr = {}
    wrW, wrH = 2, wH -- Wall width & height
    wrX, wrY = wW, wH / 2 -- Centerpoint x & y
    wr.body = love.physics.newBody world, wrX, wrY, "static"
    wr.shape = love.physics.newRectangleShape wrW, wrH
    wr.fixture = with love.physics.newFixture wr.body, wr.shape
        \setGroupIndex -1 -- Disable collision for fixtures in this group

    -- Create cart
    cart = {}
    cartW, cartH = wW / 8, 16 -- Cart width & height
    cartX, cartY = wW / 2, wH - gndH - cartH / 2 - 2 -- Centerpoint x & y
    cartD = 1 -- Cart density
    cart.body = love.physics.newBody world, cartX, cartY, "dynamic"
    cart.shape = love.physics.newRectangleShape 0, 0, cartW, cartH
    cart.fixture = with love.physics.newFixture cart.body, cart.shape, cartD
        \setRestitution 0.5 -- Bounce off walls

    -- Create first (short) pole
    p1 = {}
    p1W, p1H = 4, 1.0 * love.physics.getMeter! -- Pole width & height
    p1X, p1Y = cartX, cartY - cartH / 2 - p1H / 2 - 1 -- Centerpoint x & y
    p1D = 0.08 -- Pole density
    p1I = 0.1 -- Pole inertia
    p1.body = with love.physics.newBody world, p1X, p1Y, "dynamic"
        \setInertia p1I
        \setAngle 0
    p1.shape = love.physics.newRectangleShape 0, 0, p1W, p1H
    p1.fixture = with love.physics.newFixture p1.body, p1.shape, p1D
        \setGroupIndex -1 -- Disable collision for fixtures in this group

    -- Create second (long) pole
    p2 = {}
    p2W, p2H = 3, 2.0 * love.physics.getMeter! -- Pole width & height
    p2X, p2Y = cartX, cartY - cartH / 2 - p2H / 2 - 1 -- Centerpoint x & y
    p2D = 0.05 -- Pole density
    p2I = 0.1 -- Pole inertia
    p2.body = with love.physics.newBody world, p2X, p2Y, "dynamic"
        \setInertia p2I
        \setAngle 0
    p2.shape = love.physics.newRectangleShape 0, 0, p2W, p2H
    p2.fixture = with love.physics.newFixture p2.body, p2.shape, p2D
        \setGroupIndex -1 -- Disable collision for fixtures in this group

    -- Create joint between pole 1 & cart
    p1j = {}
    p1jX, p1jY = p1X + p1W / 2, p1Y + p1H / 2 -- Joint x & y
    p1j = love.physics.newRevoluteJoint cart.body, p1.body, p1jX, p1jY, false

    -- Create joint between pole 2 & cart
    p2j = {}
    p2jX, p2jY = p2X + p2W / 2, p2Y + p2H / 2 -- Joint x & y
    p2j = love.physics.newRevoluteJoint cart.body, p2.body, p2jX, p2jY, false

    -- Reset time and moved status
    t = 0
    moved = 0

    -- Set background
    love.graphics.setBackgroundColor 0x11, 0x11, 0x11


love.update = (dt) ->

    -- Get window dimensions
    wW, wH = love.graphics.getDimensions!

    -- Progress time
    t += dt * moved

    -- Update physics
    world\update dt

    -- Constrain the cart's velocity
    cartVelx, cartVely = cart.body\getLinearVelocity!
    if cartVelx > MaxVelx
        cart.body\setLinearVelocity MaxVelx, cartVely
    if cartVelx < -MaxVelx
        cart.body\setLinearVelocity -MaxVelx, cartVely

    -- Constrain the poles' angular velocities
    p1Avel = p1.body\getAngularVelocity!
    p2Avel = p2.body\getAngularVelocity!
    if p1Avel > MaxAvel
        p1.body\setAngularVelocity MaxAvel
    if p1Avel < -MaxAvel
        p1.body\setAngularVelocity -MaxAvel
    if p2Avel > MaxAvel
        p2.body\setAngularVelocity MaxAvel
    if p2Avel < -MaxAvel
        p2.body\setAngularVelocity -MaxAvel

    -- Handle input
    if love.keyboard.isDown "right"
        fx, fy = MaxMoveForce * 1.0, 0 -- Force magnitudes
        cart.body\applyForce fx, fy
        moved = 1
    if love.keyboard.isDown "left"
        fx, fy = MaxMoveForce * -1.0, 0 -- Force magnitudes
        cart.body\applyForce fx, fy
        moved = 1
    if love.keyboard.isDown "f1"
        love.load! -- Reload simulation


love.draw = ->

    -- Get window dimensions
    wW, wH = love.graphics.getDimensions!

    -- Colors
    white = {0xff, 0xff, 0xff}
    yellow = {0xff, 0xdc, 0x00}
    navy = {0x00, 0x1f, 0x3f}
    blue = {0x00, 0x74, 0xd9}
    aqua = {0x7f, 0xdb, 0xff}
    red = {0xff, 0x41, 0x36}

    -- Display information
    love.graphics.setColor white
    time = string.format "%.1f", t
    cartX = string.format "%.4f", cart.body\getX! / (wW / 2) - 1
    cartVelx = string.format "%.4f", cart.body\getLinearVelocity! / MaxVelx
    p1Angle = string.format "%.4f", p1.body\getAngle! / MaxAngle
    p1Avel = string.format "%.4f", p1.body\getAngularVelocity! / MaxAvel
    p2Angle = string.format "%.4f", p2.body\getAngle! / MaxAngle
    p2Avel = string.format "%.4f", p2.body\getAngularVelocity! / MaxAvel
    love.graphics.print {white, "t = ", yellow, time, yellow, "s"}, 20, 20
    love.graphics.print {white, "x = ", yellow, cartX}, 20, 40
    love.graphics.print {white, "v = ", yellow, cartVelx}, 20, 60
    love.graphics.print {white, "a1 = ", yellow, p1Angle}, 20, 80
    love.graphics.print {white, "w1 = ", yellow, p1Avel}, 20, 100
    love.graphics.print {white, "a2 = ", yellow, p2Angle}, 20, 120
    love.graphics.print {white, "w2 = ", yellow, p2Angle}, 20, 140

    -- Draw the ground and boundaries
    love.graphics.setColor navy
    gndPts = {gnd.body\getWorldPoints gnd.shape\getPoints!}
    wlPts = {wl.body\getWorldPoints wl.shape\getPoints!}
    wrPts = {wr.body\getWorldPoints wr.shape\getPoints!}
    love.graphics.polygon "fill", gndPts
    love.graphics.polygon "fill", wlPts
    love.graphics.polygon "fill", wrPts

    -- Draw the cart
    love.graphics.setColor blue
    cartPts = {cart.body\getWorldPoints cart.shape\getPoints!}
    love.graphics.polygon "line", cartPts

    -- Draw the first pole
    love.graphics.setColor aqua
    if math.abs(p1.body\getAngle! / MaxAngle) > 1
        love.graphics.setColor red
    p1Pts = {p1.body\getWorldPoints p1.shape\getPoints!}
    love.graphics.polygon "line", p1Pts

    -- Draw the second pole
    love.graphics.setColor aqua
    if math.abs(p2.body\getAngle! / MaxAngle) > 1
        love.graphics.setColor red
    p2Pts = {p2.body\getWorldPoints p2.shape\getPoints!}
    love.graphics.polygon "line", p2Pts
