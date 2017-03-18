

import SpriteKit


class GameScene: SKScene {
    //initialize
    var level: Level!
    //constant width and height of tile
    let TileWidth: CGFloat = 32.0
    let TileHeight: CGFloat = 36.0
    //gameLayer is the container for all the other layers and it’s centered on the screen
    let gameLayer = SKNode()
    //cookiesLayer is the child layer of gameLayer
    let cookiesLayer = SKNode()
    //tilesLayer is the child layer of cookiesLayer
    let tilesLayer = SKNode()
    //record the column and row numbers of the cookie that the player first touched
    private var swipeFromColumn: Int?
    private var swipeFromRow: Int?
    //the closure connect GameScene with GameViewController
    var swipeHandler: ((Swap) -> ())?
    //the selected sprite which will enlarge
    var selectionSprite = SKSpriteNode()
    //implement sound effect by using [SKAnimation.playSoundFileNamed]
    let swapSound = SKAction.playSoundFileNamed("Chomp.wav", waitForCompletion: false)
    let invalidSwapSound = SKAction.playSoundFileNamed("Error.wav", waitForCompletion: false)
    let matchSound = SKAction.playSoundFileNamed("Ka-Ching.wav", waitForCompletion: false)
    let fallingCookieSound = SKAction.playSoundFileNamed("Scrape.wav", waitForCompletion: false)
    let addCookieSound = SKAction.playSoundFileNamed("Drip.wav", waitForCompletion: false)
    //second texture of grid
    let cropLayer = SKCropNode()
    let maskLayer = SKNode()
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder) is not used in this app")
    }
    
    override init(size: CGSize) {
        super.init(size: size)
        //because the scene’s default anchorPoint is (0.5, 0.5)
        //anchorPoint represents the center of the layer’s bounds rectangle
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        
        let background = SKSpriteNode(imageNamed: "Background")
        background.size = size
        addChild(background)
        //add gameLayer
        addChild(gameLayer)
        //hide the gameLayer to animate the gamelayer aniamtion
        gameLayer.isHidden = true
        //Remember that earlier you set the anchorPoint of the scene to (0.5, 0.5)? This means that when you add children to the scene their starting point (0, 0) will automatically be in the center of the scene.
        let layerPosition = CGPoint(
            x: -TileWidth * CGFloat(NumColumns) / 2,
            y: -TileHeight * CGFloat(NumRows) / 2)
        //tilesLayer is in the bottom of cookiesLayer
        tilesLayer.position = layerPosition
        gameLayer.addChild(cropLayer)
        
        maskLayer.position = layerPosition
        cropLayer.maskNode = maskLayer
        gameLayer.addChild(tilesLayer)
        //gameLayer and cookiesLayer can be thought of these as transparent planes you can add other nodes in.
        cookiesLayer.position = layerPosition
        //gameLayer.addChild(cookiesLayer)
        cropLayer.addChild(cookiesLayer)
        //appear the maskLayer
        //cropLayer.addChild(maskLayer)
        //initialize the first touch's position
        swipeFromColumn = nil
        swipeFromRow = nil
        //When using SKLabelNode, Sprite Kit needs to load the font and convert it to a texture. That only happens once, but it does create a small delay, so it’s smart to pre-load this font before the game starts in earnest to accelerate the speed of appearance of SKLabelNode
        let _ = SKLabelNode(fontNamed: "GillSans-BoldItalic")
    }
    //add sprite to cookies layer
    func addSprites(for cookies: Set<Cookie>) {
        for cookie in cookies {
            let sprite = SKSpriteNode(imageNamed: cookie.cookieType.spriteName)
            sprite.size = CGSize(width: TileWidth, height: TileHeight)
            sprite.position = pointFor(column: cookie.column, row: cookie.row)
            cookiesLayer.addChild(sprite)
            cookie.sprite = sprite
            // Give each cookie sprite a small, random delay. Then fade them in.
            sprite.alpha = 0
            sprite.xScale = 0.5
            sprite.yScale = 0.5
            
            sprite.run(
                SKAction.sequence([
                    SKAction.wait(forDuration: 0.25, withRange: 0.5),
                    SKAction.group([
                        SKAction.fadeIn(withDuration: 0.25),
                        SKAction.scale(to: 1.0, duration: 0.25)
                        ])
                    ]))
        }
    }
    //add tilesLayer
    func addTiles() {
        for row in 0..<NumRows {
            for column in 0..<NumColumns {
                if level.tileAt(column: column, row: row) != nil {
                    //let tileNode = SKSpriteNode(imageNamed: "Tile")
                    //MaskTile is the SKCropNode's mask
                    let tileNode = SKSpriteNode(imageNamed: "MaskTile")
                    tileNode.size = CGSize(width: TileWidth, height: TileHeight)
                    tileNode.position = pointFor(column: column, row: row)
                    //tilesLayer.addChild(tileNode)
                    maskLayer.addChild(tileNode)
                }
                
            }
        }
    }
    //convert Int to CGFloat
    func pointFor(column: Int, row: Int) -> CGPoint {
        return CGPoint(
            x: CGFloat(column)*TileWidth + TileWidth/2,
            y: CGFloat(row)*TileHeight + TileHeight/2)
    }
    //convert CGFloat to Int(the opposite of function of pointFor)
    func convertPoint(point: CGPoint) -> (success: Bool, column: Int, row: Int) {
        if point.x >= 0 && point.x < CGFloat(NumColumns)*TileWidth &&
            point.y >= 0 && point.y < CGFloat(NumRows)*TileHeight {
            return (true, Int(point.x / TileWidth), Int(point.y / TileHeight))
        } else {
            //if the point that player touch is out of the grid and it will return false
            return (false, 0, 0)  // invalid location
        }
    }
    //touchBegan
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        //convert the location position to a point relative to the cookiesLayer
        guard let touch = touches.first else { return }
        let location = touch.location(in: cookiesLayer)
        //
        let (success, column, row) = convertPoint(point:location)
        if success {
            //verifies that the touch is on a cookie rather than on an empty square
            if let cookie = level.cookieAt(column: column, row: row) {
                //picture enlarge when it was selected
                showSelectionIndicatorForCookie(cookie: cookie)
                //records the column and row where the swipe started
                swipeFromColumn = column
                swipeFromRow = row
            }
        }
    }
    //touch move
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        // 1
        guard swipeFromColumn != nil else { return }
        
        // 2
        guard let touch = touches.first else { return }
        let location = touch.location(in: cookiesLayer)
        
        let (success, column, row) = convertPoint(point:location)
        if success {
            
            //figures out the direction of the player’s swipe by simply comparing the new column and row numbers to the previous ones
            var horzDelta = 0, vertDelta = 0
            if column < swipeFromColumn! {          // swipe left
                horzDelta = -1
            } else if column > swipeFromColumn! {   // swipe right
                horzDelta = 1
            } else if row < swipeFromRow! {         // swipe down
                vertDelta = -1
            } else if row > swipeFromRow! {         // swipe up
                vertDelta = 1
            }
            
            //The method only performs the swap if the player swiped out of the old square.
            if horzDelta != 0 || vertDelta != 0 {
                trySwap(horizontal: horzDelta, vertical: vertDelta)
                
                //ignore the rest of this swipe motion
                swipeFromColumn = nil
            }
        }
    }
    //
    func trySwap(horizontal horzDelta: Int, vertical vertDelta: Int) {
        //picture min
        hideSelectionIndicator()
        //the column and row numbers of the cookie to swap with
        let toColumn = swipeFromColumn! + horzDelta
        let toRow = swipeFromRow! + vertDelta
        //ignore such swipes that is outside the 9×9 grid
        guard toColumn >= 0 && toColumn < NumColumns else { return }
        guard toRow >= 0 && toRow < NumRows else { return }
        //make sure that there is actually a cookie at the new position
        if let toCookie = level.cookieAt(column: toColumn, row: toRow),
            let fromCookie = level.cookieAt(column: swipeFromColumn!, row: swipeFromRow!) {
            //waiting the swap function
            //print("*** swapping \(fromCookie) with \(toCookie)")
            if let handler = swipeHandler {
                let swap = Swap(cookieA: fromCookie, cookieB: toCookie)
                handler(swap)
            }
        }
    }
    //the swap animation+closure function
    func animate(_ swap: Swap, completion: @escaping () -> ()) {
        let spriteA = swap.cookieA.sprite!
        let spriteB = swap.cookieB.sprite!
        
        spriteA.zPosition = 100
        spriteB.zPosition = 90
        
        let duration: TimeInterval = 0.3
        
        let moveA = SKAction.move(to: spriteB.position, duration: duration)
        moveA.timingMode = .easeOut
        spriteA.run(moveA, completion: completion)
        
        let moveB = SKAction.move(to: spriteA.position, duration: duration)
        moveB.timingMode = .easeOut
        spriteB.run(moveB)
        
        //swapSound
        //run is using to play SKAnimation
        run(swapSound)
    }
    //show larger picture when it was selected
    func showSelectionIndicatorForCookie(cookie: Cookie) {
        if selectionSprite.parent != nil {
            selectionSprite.removeFromParent()
        }
        
        if let sprite = cookie.sprite {
            let texture = SKTexture(imageNamed: cookie.cookieType.highlightedSpriteName)
            selectionSprite.size = CGSize(width: TileWidth, height: TileHeight)
            selectionSprite.run(SKAction.setTexture(texture))
            
            sprite.addChild(selectionSprite)
            selectionSprite.alpha = 1.0
        }
    }
    //Add the opposite method above
    func hideSelectionIndicator() {
        selectionSprite.run(SKAction.sequence([
            SKAction.fadeOut(withDuration: 0.3),
            SKAction.removeFromParent()]))
    }
    
    //animate attempted swaps that are invalid
    //it slides the cookies to their new positions and then immediately flips them back.
    func animateInvalidSwap(_ swap: Swap, completion: @escaping () -> ()) {
        let spriteA = swap.cookieA.sprite!
        let spriteB = swap.cookieB.sprite!
        
        spriteA.zPosition = 100
        spriteB.zPosition = 90
        
        let duration: TimeInterval = 0.2
        
        let moveA = SKAction.move(to: spriteB.position, duration: duration)
        moveA.timingMode = .easeOut
        
        let moveB = SKAction.move(to: spriteA.position, duration: duration)
        moveB.timingMode = .easeOut
        
        spriteA.run(SKAction.sequence([moveA, moveB]), completion: completion)
        spriteB.run(SKAction.sequence([moveB, moveA]))
        
        //invalid swap sound
        run(invalidSwapSound)
    }
    //remove cookies from view with a animation
    func animateMatchedCookies(for chains: Set<Chain>, completion: @escaping () -> ()) {
        for chain in chains {
            //score animate before the aniamtion of cookies disappearance
            animateScore(for: chain)
            for cookie in chain.cookies {
                if let sprite = cookie.sprite {
                    if sprite.action(forKey: "removing") == nil {
                        let scaleAction = SKAction.scale(to: 0.1, duration: 0.3)
                        scaleAction.timingMode = .easeOut
                        sprite.run(SKAction.sequence([scaleAction, SKAction.removeFromParent()]),
                                   withKey:"removing")
                    }
                }
            }
        }
        //the sound effct
        run(matchSound)
        //ensures that the rest of the game will only continue after the animations finish
        run(SKAction.wait(forDuration: 0.3), completion: completion)
    }
    
    //falling cookies to holes with a animation
    func animateFallingCookies(columns: [[Cookie]], completion: @escaping () -> ()) {
        //can't hardcode the duration of falling animation
        var longestDuration: TimeInterval = 0
        for array in columns {
            for (idx, cookie) in array.enumerated() {
                let newPosition = pointFor(column: cookie.column, row: cookie.row)
                //The higher up the cookie is, the bigger the delay on the animation
                let delay = 0.05 + 0.15*TimeInterval(idx)
                //the duration of the animation is based on how far the cookie has to fall (0.1 seconds per tile)
                let sprite = cookie.sprite!   // sprite always exists at this point
                let duration = TimeInterval(((sprite.position.y - newPosition.y) / TileHeight) * 0.1)
                //calculate the longest time to wait
                longestDuration = max(longestDuration, duration + delay)
                //falling animation
                let moveAction = SKAction.move(to: newPosition, duration: duration)
                moveAction.timingMode = .easeOut
                sprite.run(
                    SKAction.sequence([
                        SKAction.wait(forDuration: delay),
                        SKAction.group([moveAction, fallingCookieSound])]))
            }
        }
        
        // 6
        run(SKAction.wait(forDuration: longestDuration), completion: completion)
    }
    //add new cookie with aniamtion
    //the difference between the function above is the loop's sequence
    func animateNewCookies(_ columns: [[Cookie]], completion: @escaping () -> ()) {
        //the longest time to waite
        var longestDuration: TimeInterval = 0
        
        for array in columns {
            //
            let startRow = array[0].row + 1
            
            for (idx, cookie) in array.enumerated() {
                // 3
                let sprite = SKSpriteNode(imageNamed: cookie.cookieType.spriteName)
                sprite.size = CGSize(width: TileWidth, height: TileHeight)
                sprite.position = pointFor(column: cookie.column, row: startRow)
                cookiesLayer.addChild(sprite)
                cookie.sprite = sprite
                // 4
                let delay = 0.1 + 0.2 * TimeInterval(array.count - idx - 1)
                // 5
                let duration = TimeInterval(startRow - cookie.row) * 0.1
                longestDuration = max(longestDuration, duration + delay)
                //the aniamtion is falling down and fadein
                let newPosition = pointFor(column: cookie.column, row: cookie.row)
                let moveAction = SKAction.move(to: newPosition, duration: duration)
                moveAction.timingMode = .easeOut
                sprite.alpha = 0
                sprite.run(
                    SKAction.sequence([
                        SKAction.wait(forDuration: delay),
                        SKAction.group([
                            SKAction.fadeIn(withDuration: 0.05),
                            moveAction,
                            addCookieSound])
                        ]))
            }
        }
        // 7
        run(SKAction.wait(forDuration: longestDuration), completion: completion)
    }
    //function of score animation in cookies
    func animateScore(for chain: Chain) {
        // Figure out what the midpoint of the chain is.
        let firstSprite = chain.firstCookie().sprite!
        let lastSprite = chain.lastCookie().sprite!
        let centerPosition = CGPoint(
            x: (firstSprite.position.x + lastSprite.position.x)/2,
            y: (firstSprite.position.y + lastSprite.position.y)/2 - 8)
        
        // Add a label for the score that slowly floats up.
        let scoreLabel = SKLabelNode(fontNamed: "GillSans-BoldItalic")
        scoreLabel.fontSize = 16
        scoreLabel.text = String(format: "%ld", chain.score)
        scoreLabel.position = centerPosition
        scoreLabel.zPosition = 300
        cookiesLayer.addChild(scoreLabel)
        
        let moveAction = SKAction.move(by: CGVector(dx: 0, dy: 3), duration: 0.7)
        moveAction.timingMode = .easeOut
        scoreLabel.run(SKAction.sequence([moveAction, SKAction.removeFromParent()]))
    }
    //animateGameOver() animates the entire gameLayer out of the way.
    func animateGameOver(_ completion: @escaping () -> ()) {
        let action = SKAction.move(by: CGVector(dx: 0, dy: -size.height), duration: 0.3)
        action.timingMode = .easeIn
        gameLayer.run(action, completion: completion)
    }
    //animateBeginGame() does the opposite and slides the gameLayer back in from the top of the screen.
    func animateBeginGame(_ completion: @escaping () -> ()) {
        gameLayer.isHidden = false
        gameLayer.position = CGPoint(x: 0, y: size.height)
        let action = SKAction.move(by: CGVector(dx: 0, dy: -size.height), duration: 0.3)
        action.timingMode = .easeOut
        gameLayer.run(action, completion: completion)
    }
    //clean up the old cookies
    func removeAllCookieSprites() {
        cookiesLayer.removeAllChildren()
    }
    //touch ended
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        //only tap and not moving
        if selectionSprite.parent != nil && swipeFromColumn != nil {
            hideSelectionIndicator()
        }
        //reset the starting column and row numbers to the special value nil
        swipeFromColumn = nil
        swipeFromRow = nil
    }
    //happens when iOS decides that it must interrupt the touch (for example, because of an incoming phone call)
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchesEnded(touches, with: event)
    }
    
}
