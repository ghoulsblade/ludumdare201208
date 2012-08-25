gKeyPressed = {}

function GfxSetPixelArtFilter (gfx) gfx:setFilter("nearest","nearest") return gfx end

function love.load()
	gTitleScreen = GfxSetPixelArtFilter(love.graphics.newImage("data/titelscreen.jpg"))
end

function love.mousepressed(x,y,btn)
end

function love.keypressed( key, unicode )
    gKeyPressed[key] = true
    if (key == "escape") then os.exit(0) end
end
function love.keyreleased( key )
    gKeyPressed[key] = nil
end

function love.update( dt )
end

function love.draw()
	love.graphics.draw(gTitleScreen, 0,0, 0, 1,1)
end
