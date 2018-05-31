-----------------------------------------------------------------------------------------
--
-- gameScene.lua
--
-- Created By: Fawaz Mezher
-- Created On: May 2018
-----------------------------------------------------------------------------------------
local composer = require( "composer" )
local physics = require( "physics" )
local json = require( "json" )
local tiled = require( "com.ponywolf.ponytiled" )

local scene = composer.newScene()

-- Forward reference
local ninjaBoy = nil
local map = nil
local rightArrow = nil
local jumpButton = nil
local shootButton = nil
local playerBullets = {}

-- Function to chaneg sequence 
local function onRightArrowClicked( event )
    if ( event.phase == "began" ) then 
        if ninjaBoy.sequence ~= "run" then 
            ninjaBoy.sequence = "run"
            ninjaBoy:setSequence( "run" )
            ninjaBoy:play()
        end    
    
    elseif ( event.phase == "ended" ) then   
        if ninjaBoy.sequence ~= "idle" then 
            ninjaBoy.sequence = "idle"
            ninjaBoy:setSequence( "idle" )
            ninjaBoy:play()
        end 
    end 
    
    return true    
end

local function onJumpButtonClicked( event )
    if ( event.phase == "began" ) then 
        if ninjaBoy.sequence ~= "jump" then
            ninjaBoy.sequence = "jump"
            ninjaBoy:setLinearVelocity( 150, -500 )
            ninjaBoy:setSequence( "jump" )
            ninjaBoy:play()
        end
   end  

   return true  
end

-- move ninja
local function moveNinja( event )
    if ninjaBoy.sequence == "run" then
        transition.moveBy( ninjaBoy, {
            x = 10,
            y = 0,
            time = 0
            } )
    end     
    
    if ninjaBoy.sequence == "jump" then
        local linearVelocityX, linearVelocityY = ninjaBoy:getLinearVelocity()

        if linearVelocityX == 0 then
            ninjaBoy.sequence = "idle"
            ninjaBoy:setSequence( "idle" )
            ninjaBoy:play()
        end
    end

    return true
end


local function resetAfterThrow( event )
    ninjaBoy.sequence = "idle"
    ninjaBoy:setSequence( "idle" )
    ninjaBoy:play()
end

function onthrowButtonClicked( event )
    if ( event.phase == "began" ) then
        if ninjaBoy.sequence ~= "throw" then 
            ninjaBoy.sequence = "throw"
            ninjaBoy:setSequence( "throw" )
            ninjaBoy:play()
            timer.performWithDelay( 800, resetAfterThrow )

        -- use function to delay throw to match animation
            local function delayThrow( event )
                local aSingleBullet = display.newImage( "./assets/sprites/Kunai.png" )
                 -- puts bullet on screen at character postion
                aSingleBullet.x = ninjaBoy.x
                aSingleBullet.y = ninjaBoy.y
                physics.addBody( aSingleBullet, 'dynamic' )
                -- Makes sprite a "bullet" type object
                aSingleBullet.isBullet = true
                aSingleBullet.gravityScale = 0
                aSingleBullet.id = "bullet"
                aSingleBullet:setLinearVelocity( 1500, 0 )
                aSingleBullet.isFixedRotation = true
        
                table.insert(playerBullets,aSingleBullet)
                print("# of bullet: " .. tostring(#playerBullets))    
            end 
        timer.performWithDelay( 200, delayThrow )
        
        
        end
    end

    return true
end

local function checkPlayerBulletsOutOfBounds()
    -- check if bullets are off the screen and rmoves them 
    local bulletCounter

    if #playerBullets > 0 then
        for bulletCounter = #playerBullets, 1 ,-1 do
            if playerBullets[bulletCounter].x > display.contentWidth + 1000 then
                playerBullets[bulletCounter]:removeSelf()
                playerBullets[bulletCounter] = nil
                table.remove(playerBullets, bulletCounter)
                print("remove bullet")
            end
        end
    end
end

local function onCollision( event )
 
    if ( event.phase == "began" ) then
 
        local obj1 = event.object1
        local obj2 = event.object2

        if ( ( obj1.id == "enemy" and obj2.id == "bullet" ) or
             ( obj1.id == "bullet" and obj2.id == "enemy" ) ) then
            -- Table of emitter parameters
            local emitterParams = {
                startColorAlpha = 1,
                startParticleSizeVariance = 500,
                startColorGreen = 0,
                yCoordFlipped = -1,
                blendFuncSource = 770,
                rotatePerSecondVariance = 153.95,
                particleLifespan = 0.8,
                tangentialAcceleration = -1440.74,
                finishColorBlue = 0.5,
                finishColorGreen = 0,
                blendFuncDestination = 1,
                startParticleSize = 400.95,
                startColorRed = 0.8373094,
                textureFileName = "./assets/sprites/fire.png",
                startColorVarianceAlpha = 1,
                maxParticles = 256,
                finishParticleSize = 600,
                duration = 0.25,
                finishColorRed = 1,
                maxRadiusVariance = 72.63,
                finishParticleSizeVariance = 250,
                gravityy = 671.05,
                speedVariance = 90.79,
                tangentialAccelVariance = -420.11,
                angleVariance = -142.62,
                angle = -244.11
            }
            -- show explosion
            local emitter = display.newEmitter( emitterParams )
            emitter.x = obj1.x
            emitter.y = obj1.y

            -- Remove bullet
            for bulletCounter = #playerBullets, 1, -1 do
                if ( playerBullets[bulletCounter] == obj1 or playerBullets[bulletCounter] == obj2 ) then
                    playerBullets[bulletCounter]:removeSelf()
                    playerBullets[bulletCounter] = nil
                    table.remove( playerBullets, bulletCounter )
                    break
                end
            end


            -- Remove character
            enemy:setSequence( 'deadEnemy' )
            enemy:play()
            transition.fadeOut( enemy, { time = 1300 } )
            
            -- remove after delay
            local function removeEnemy( event )
                enemy:removeSelf()
                enemy = nil
            end

            timer.performWithDelay( 1200, removeEnemy )

            -- Play Explosion sound 
            local expolsionSound = audio.loadSound( "./assets/sounds/8bit_bomb_explosion.wav" )
            audio.play( expolsionSound )

        end
    end
end

-- create()
function scene:create( event )
 
    local sceneGroup = self.view

    physics.start()
    physics.setGravity( 0, 20 )

    -- show map 
    local filename = "assets/maps/level0.json"
    local mapData = json.decodeFile( system.pathForFile( filename, system.ResourceDirectory ) )
    map = tiled.new( mapData, "assets/maps" )

    local sheetOptionsIdleBoy = require( "assets.spritesheets.ninjaBoy.ninjaBoyIdle" )
    local sheetBoyIdle = graphics.newImageSheet( "./assets/spritesheets/ninjaBoy/ninjaBoyIdle.png", sheetOptionsIdleBoy:getSheet() )

    local sheetOptionsRunBoy = require( "assets.spritesheets.ninjaBoy.ninjaBoyRun" )
    local sheetBoyRun = graphics.newImageSheet( "./assets/spritesheets/ninjaBoy/ninjaBoyRun.png", sheetOptionsRunBoy:getSheet() )

    local sheetOptionsJumpBoy = require( "assets.spritesheets.ninjaBoy.ninjaBoyJump" )
    local sheetBoyJump = graphics.newImageSheet( "./assets/spritesheets/ninjaBoy/ninjaBoyJump.png", sheetOptionsJumpBoy:getSheet() )

    local sheetOptionsThrowBoy = require( "assets.spritesheets.ninjaBoy.ninjaBoyThrow" )
    local sheetBoyThrow = graphics.newImageSheet( "./assets/spritesheets/ninjaBoy/ninjaBoyThrow.png", sheetOptionsThrowBoy:getSheet() )

    local sheetOptionsIdleEnemy = require( "assets.spritesheets.ninjaGirl.ninjaGirlIdle" )
    local sheetEnemyIdle = graphics.newImageSheet( "./assets/spritesheets/ninjaGirl/ninjaGirlIdle.png", sheetOptionsIdleEnemy:getSheet() )

    local sheetOptionsDeadEnemy = require( "assets.spritesheets.ninjaGirl.ninjaGirlDead" )
    local sheetEnemyDead = graphics.newImageSheet( "./assets/spritesheets/ninjaGirl/ninjaGirlDead.png", sheetOptionsDeadEnemy:getSheet() )


    
    local sequence_data = {
        {
            name = "idle",
            start = 1, 
            count = 10,
            time = 800, 
            loopCount = 0,
            sheet = sheetBoyIdle
        },
        {
            name = "run",
            start = 1, 
            count = 10,
            time = 800, 
            loopCount = 0,
            sheet = sheetBoyRun
        },
        {
            name = "jump",
            start = 1, 
            count = 10,
            time = 1000, 
            loopCount = 1,
            sheet = sheetBoyJump
        },
        {
            name = "throw",
            start = 1, 
            count = 10,
            time = 750, 
            loopCount = 1,
            sheet = sheetBoyThrow
        },
        {
            name = "idleEnemy",
            start = 1, 
            count = 10,
            time = 750, 
            loopCount = 0,
            sheet = sheetEnemyIdle
        },
        {
            name = "deadEnemy",
            start = 1, 
            count = 10,
            time = 750, 
            loopCount = 1,
            sheet = sheetEnemyDead
        }
    }

    -- show ninjaBoy
    ninjaBoy = display.newSprite( sheetBoyIdle, sequence_data )
    ninjaBoy.x = display.contentWidth / 2 
    ninjaBoy.y = 0
    ninjaBoy.sequence = "idle"
    ninjaBoy.id = "ninja Boy"
    physics.addBody( ninjaBoy, "dynamic", { 
        friction = 0.5, 
        bounce = 0.3 
        } )
    ninjaBoy.isFixedRotation = true
    ninjaBoy:setSequence( "idleBoy" )
    ninjaBoy:play()

    enemy = display.newSprite( sheetEnemyIdle, sequence_data )
    enemy.x = display.contentWidth - 300
    enemy.y = 0
    enemy.sequence = "idleEnemy"
    enemy.id = "enemy"
    enemy.xScale = -1
    physics.addBody( enemy, "dynamic", { 
        friction = 0.5, 
        bounce = 0.3 
        } )
    enemy.isFixedRotation = true
    enemy:setSequence( "idleEnemy" )
    enemy:play()

    rightArrow = display.newImage( "./assets/sprites/rightButton.png" )
    rightArrow.x = 300
    rightArrow.y = 1300
    rightArrow.id = "right Arrow"
    rightArrow.alpha = 0.7

    jumpButton = display.newImage( "./assets/sprites/jumpButton.png" )
    jumpButton.x  = 1500
    jumpButton.y = 1300
    jumpButton.id = "jump Button"
    jumpButton.alpha = 0.7

    throwButton = display.newImage( "./assets/sprites/jumpButton.png" )
    throwButton.x  = 1700
    throwButton.y = 1300
    throwButton.id = "throw Button"
    throwButton.alpha = 0.7

    sceneGroup:insert( map )
    sceneGroup:insert( ninjaBoy )
    sceneGroup:insert( enemy )
    sceneGroup:insert( rightArrow )
    sceneGroup:insert( jumpButton )
    sceneGroup:insert( throwButton )

end

-- show()
function scene:show( event )
 
    local sceneGroup = self.view
    local phase = event.phase
 
    if ( phase == "will" ) then
     
    elseif ( phase == "did" ) then
        rightArrow:addEventListener( "touch", onRightArrowClicked )
        jumpButton:addEventListener( "touch", onJumpButtonClicked )
        throwButton:addEventListener( "touch", onthrowButtonClicked )

        Runtime:addEventListener( "collision", onCollision )
        Runtime:addEventListener( "enterFrame", moveNinja )
        Runtime:addEventListener( "enterFrame", checkPlayerBulletsOutOfBounds )
    end
end
 
 
-- hide()
function scene:hide( event )
 
    local sceneGroup = self.view
    local phase = event.phase
 
    if ( phase == "will" ) then
        -- Code here runs when the scene is on screen (but is about to go off screen)
 
    elseif ( phase == "did" ) then
        -- Code here runs immediately after the scene goes entirely off screen
        rightArrow:removeEventListener( "touch", onRightArrowClicked )
        jumpButton:removeEventListener( "touch", onJumpButtonClicked )
        throwButton:removeEventListener( "touch", onthrowButtonClicked )

        Runtime:removeEventListener( "collision", onCollision )
        Runtime:removeEventListener( "enterFrame", moveNinja )
        Runtime:removeEventListener( "enterFrame", checkPlayerBulletsOutOfBounds )
    end
end
 
 
-- destroy()
function scene:destroy( event )
 
    local sceneGroup = self.view
    -- Code here runs prior to the removal of scene's view
 
end
 
 
-- -----------------------------------------------------------------------------------
-- Scene event function listeners
-- -----------------------------------------------------------------------------------
scene:addEventListener( "create", scene )
scene:addEventListener( "show", scene )
scene:addEventListener( "hide", scene )
scene:addEventListener( "destroy", scene )
-- -----------------------------------------------------------------------------------
 
return scene