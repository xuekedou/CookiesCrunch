//
//  GameViewController.swift
//  CookieCrunch
//
//  Created by xsf on 2017/3/15.
//  Copyright © 2017年 xsf. All rights reserved.
//

//You’ll still have a scene object—GameScene from the template—but this will only be responsible for drawing the sprites; GameViewController will handle any of the game logic.
import UIKit
import SpriteKit
import AVFoundation

class GameViewController: UIViewController {
    
    //add GameScene(view) to ViewController
    var scene: GameScene!
    //add level(model) to viewController
    var level : Level!
    
    //scoring record
    var movesLeft = 0
    var score = 0
    
    //label of scoring
    @IBOutlet weak var targetLabel: UILabel!
    
    @IBOutlet weak var movesLabel: UILabel!
    
    @IBOutlet weak var scoreLabel: UILabel!
    
    //game over scene
    @IBOutlet weak var gameOverPanel: UIImageView!
//    //shuffleButton
    @IBOutlet weak var shuffleButton: UIButton!
//    //the function of button being clicked
    @IBAction func shuffleButtonPressed(_: AnyObject) {
        shuffle()
        decrementMoves()
    }
    
    //gesture
    var tapGestureRecognizer: UITapGestureRecognizer!
    //the property of background music
    //this is a common pattern for declaring a variable and initializing it in the same statement for background music
    lazy var backgroundMusic: AVAudioPlayer? = {
        guard let url = Bundle.main.url(forResource: "Mining by Moonlight", withExtension: "mp3") else {
            return nil
        }
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.numberOfLoops = -1
            return player
        } catch {
            return nil
        }
    }()
    //keeping track of the level the user is currently playing
    var currentLevelNum = 1
    //kick off the game by calling shuffle function
    //they are just model data without any sprite
    
    func shuffle() {
        //remove old cookies before shuffle new cookies
        scene.removeAllCookieSprites()
        //conect the view and model
        let newCookies = level.shuffle()
        scene.addSprites(for: newCookies)
    }
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override var shouldAutorotate: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return [.portrait, .portraitUpsideDown]
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Setup view with level 1
        setupLevel(levelNum: currentLevelNum)
        //play backgound music by "play" function of system
        backgroundMusic?.play()
        
        
        
    }
    func setupLevel(levelNum: Int) {
        //hide the button when the game first start
        shuffleButton.isHidden = true
        // Configure the view.
        let skView = view as! SKView
        skView.isMultipleTouchEnabled = false
        
        // Create and configure the scene.
        scene = GameScene(size: skView.bounds.size)
        scene.scaleMode = .aspectFill
        
        //create level instance
        //tie together the model and the view
        level = Level(filename: "Level_\(levelNum)")
        scene.level = level
        //add tiles to scene
        scene.addTiles()
        //before present the scene, make sure to hide this image view of gameover
        gameOverPanel.isHidden = true
        // Present the scene.
        skView.presentScene(scene)
        beginGame()
        //swiphandle
        scene.swipeHandler = handleSwipe
    }
    func beginGame() {
        //add label
        movesLeft = level.maximumMoves
        score = 0
        updateLabels()
        //reset combo
        level.resetComboMultiplier()
        //start begin game animation
        //put back the shuffleButton
        scene.animateBeginGame() {
            self.shuffleButton.isHidden = false
        }
        //shuffle cookie
        shuffle()
        
    }

    //handle matches
    func handleMatches() {
        let chains = level.removeMatches()
        // TODO: do something with the chains set
        
        //there is no more matches
        if chains.count == 0 {
            beginNextTurn()
            //the content after the "return" will not runing!!!!
            return
        }
        //the animation of chain match
        scene.animateMatchedCookies(for: chains) {
            //calculate the scores
            for chain in chains {
                self.score += chain.score
            }
            self.updateLabels()
            //tie the level(model) and scene(view) together
            //in swift,it is not neccessary to use self except inside closure
            let columns = self.level.fillHoles()
            self.scene.animateFallingCookies(columns: columns){
                let columns = self.level.topUpCookies()
                self.scene.animateNewCookies(columns){
                    //self.view.isUserInteractionEnabled = true
                    //Recursion
                    self.handleMatches()
                }
            }
        }
    }
    //active the function after cookies matching happen
    func beginNextTurn() {
        //reset combo
        level.resetComboMultiplier()
        //recalculate this update list of possible swap
        level.detectPossibleSwaps()
        view.isUserInteractionEnabled = true
        //decrease the left movements
        decrementMoves()
    }
    //handle swip to swap of two sprite
    func handleSwipe(swap: Swap) {
        view.isUserInteractionEnabled = false
        if level.isPossibleSwap(swap){
            level.performSwap(swap: swap)
            //turn on to let user can handle the screen
            scene.animate(swap, completion: handleMatches)
//            scene.animate(swap) {
//                self.view.isUserInteractionEnabled = true
//                
//            }

        }else{
            scene.animateInvalidSwap(swap){
            //allow user to handle the screen only without swap animation
                self.view.isUserInteractionEnabled = true
    
            }
        }
    }
    
    //update the label's value
    func updateLabels() {
        targetLabel.text = String(format: "%ld", level.targetScore)
        movesLabel.text = String(format: "%ld", movesLeft)
        scoreLabel.text = String(format: "%ld", score)
    }
    //decrease the max movements
    func decrementMoves() {
        movesLeft -= 1
        updateLabels()
        //two situation present the gameover scene and levelComplete scene
        if score >= level.targetScore {
            gameOverPanel.image = UIImage(named: "LevelComplete")
            currentLevelNum = currentLevelNum < NumLevels ? currentLevelNum+1 : 1
            showGameOver()
        } else if movesLeft == 0 {
            gameOverPanel.image = UIImage(named: "GameOver")
            showGameOver()
        }
    }
    //the function show the gameover scene
    func showGameOver() {
        gameOverPanel.isHidden = false
        scene.isUserInteractionEnabled = false
        scene.animateGameOver {
            self.tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.hideGameOver))
            self.view.addGestureRecognizer(self.tapGestureRecognizer)
        }
        //hide the button
        shuffleButton.isHidden = true
        
    }
    
    //gameover scene disappear and begin game
    func hideGameOver() {
        view.removeGestureRecognizer(tapGestureRecognizer)
        tapGestureRecognizer = nil
        
        gameOverPanel.isHidden = true
        scene.isUserInteractionEnabled = true
        
        //beginGame()
        //set up the level of the game
        setupLevel(levelNum: currentLevelNum)
    }
}
