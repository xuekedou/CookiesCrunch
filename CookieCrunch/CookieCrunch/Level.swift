//
//  Level.swift
//  CookieCrunch
//
//  Created by xsf on 2017/3/16.
//  Copyright © 2017年 xsf. All rights reserved.
//

import Foundation

let NumColumns = 9
let NumRows = 9
//keep track of the row
let NumLevels = 4 // Excluding level 0
//the set which store the possible Swap to generate line
//Set's protocal must implement Hashable protocal
private var possibleSwaps = Set<Swap>()

class Level {
    //load the target score and the maximum number of moves
    //the initialize parameter show declare in the class!!!!
    var targetScore = 0
    var maximumMoves = 0
    fileprivate var cookies = Array2D<Cookie>(columns: NumColumns, rows: NumRows)
    
    //combo
    private var comboMultiplier = 0
    //cookie is Private,so this is the function to get the position of cookie for others
    func cookieAt(column: Int, row: Int) -> Cookie? {
        //better than if to assert whether it meets this condition
        assert(column >= 0 && column < NumColumns)
        assert(row >= 0 && row < NumRows)
        return cookies[column, row]
    }
    //function to fill the screen with cookies
    func shuffle() -> Set<Cookie> {
        //return createInitialCookies()
        var set: Set<Cookie>
        repeat {
            //fill with cookie
            set = createInitialCookies()
            //fill up the new possibleSwaps set
            detectPossibleSwaps()
            print("possible swaps: \(possibleSwaps)")
        } while possibleSwaps.count == 0
        
        return set
    }
    //see if a cookie is part of a chain
    private func hasChainAt(column: Int, row: Int) -> Bool {
        let cookieType = cookies[column, row]!.cookieType
        
        // Horizontal chain check
        var horzLength = 1
        
        // Left
        var i = column - 1
        while i >= 0 && cookies[i, row]?.cookieType == cookieType {
            i -= 1
            horzLength += 1
        }
        
        // Right
        i = column + 1
        while i < NumColumns && cookies[i, row]?.cookieType == cookieType {
            i += 1
            horzLength += 1
        }
        //horizontal line
        if horzLength >= 3 { return true }
        
        // Vertical chain check
        var vertLength = 1
        
        // Down
        i = row - 1
        while i >= 0 && cookies[column, i]?.cookieType == cookieType {
            i -= 1
            vertLength += 1
        }
        // Up
        i = row + 1
        while i < NumRows && cookies[column, i]?.cookieType == cookieType {
            i += 1
            vertLength += 1
        }
        //vertical line
        return vertLength >= 3
    }
    
    //detect possible swap
    func detectPossibleSwaps() {
        var set = Set<Swap>()
        
        for row in 0..<NumRows {
            for column in 0..<NumColumns {
                if let cookie = cookies[column, row] {
                    
                    // TODO: detection logic goes here
                    //should only detect above and right from the left-bottom!!!
                    
                    //first part:attempts to swap the current cookie with the cookie on the right
                    // Is it possible to swap this cookie with the one on the right?
                    if column < NumColumns - 1 {
                        // Have a cookie in this spot? If there is no tile, there is no cookie.
                        if let other = cookies[column + 1, row] {
                            // Swap them
                            cookies[column, row] = other
                            cookies[column + 1, row] = cookie
                            
                            // Is either cookie now part of a chain?
                            if hasChainAt(column: column + 1, row: row) ||
                                hasChainAt(column: column, row: row) {
                                set.insert(Swap(cookieA: cookie, cookieB: other))
                            }
                            
                            // Swap them back
                            cookies[column, row] = cookie
                            cookies[column + 1, row] = other
                        }
                    }
                    //second part:attempts to swap the current cookie with the cookie above
                    if row < NumRows - 1 {
                        if let other = cookies[column, row + 1] {
                            cookies[column, row] = other
                            cookies[column, row + 1] = cookie
                            
                            // Is either cookie now part of a chain?
                            if hasChainAt(column: column, row: row + 1) ||
                                hasChainAt(column: column, row: row) {
                                set.insert(Swap(cookieA: cookie, cookieB: other))
                            }
                            
                            // Swap them back
                            cookies[column, row] = cookie
                            cookies[column, row + 1] = other
                        }
                    }
                }
            }
        }
        
        possibleSwaps = set
    }
    //whethe the cookie that swipe can be swap
    func isPossibleSwap(_ swap: Swap) -> Bool {
        return possibleSwaps.contains(swap)
    }
    private func createInitialCookies() -> Set<Cookie> {
        var set = Set<Cookie>()
        
        // 1
        for row in 0..<NumRows {
            for column in 0..<NumColumns {
                
                if tiles[column,row] != nil{
                //var cookieType = CookieType.random()
                var cookieType: CookieType
                    
//              In pseudo-code, it looks like this
//              repeat {
//                    generate a new random cookie type
//                }
//                while there are already two cookies of this type to the left
//                or there are already two cookies of this type below
                repeat {
                    cookieType = CookieType.random()
                //makes sure that it never creates a chain of three or more
                } while (column >= 2 &&
                    cookies[column - 1, row]?.cookieType == cookieType &&
                    cookies[column - 2, row]?.cookieType == cookieType)
                    || (row >= 2 &&
                        cookies[column, row - 1]?.cookieType == cookieType &&
                        cookies[column, row - 2]?.cookieType == cookieType)
                
                // 3
                let cookie = Cookie(column: column, row: row, cookieType: cookieType)
                cookies[column, row] = cookie
                
                // 4
                set.insert(cookie)
                    
                }
            }
        }
        return set
    }
    //tiles describes the structure of the level
    private var tiles = Array2D<Tile>(columns: NumColumns, rows: NumRows)
    
    func tileAt(column: Int, row: Int) -> Tile? {
        assert(column >= 0 && column < NumColumns)
        assert(row >= 0 && row < NumRows)
        return tiles[column, row]
    }
    //swap
    func performSwap(swap: Swap) {
        //copy
        let columnA = swap.cookieA.column
        let rowA = swap.cookieA.row
        let columnB = swap.cookieB.column
        let rowB = swap.cookieB.row
        //swap
        cookies[columnA, rowA] = swap.cookieB
        swap.cookieB.column = columnA
        swap.cookieB.row = rowA
        
        cookies[columnB, rowB] = swap.cookieA
        swap.cookieA.column = columnB
        swap.cookieA.row = rowB
    }
    
    //detect horizontal matches
    private func detectHorizontalMatches() -> Set<Chain> {
        //set to hold the horizontal chain
        var set = Set<Chain>()
        //loop except the last 2 columns
        for row in 0..<NumRows {
            var column = 0
            while column < NumColumns-2 {
                //skip gap
                if let cookie = cookies[column, row] {
                    let matchType = cookie.cookieType
                    //check the next two cookies
                    if cookies[column + 1, row]?.cookieType == matchType &&
                        cookies[column + 2, row]?.cookieType == matchType {
                        //add potentional same type cookies
                        let chain = Chain(chainType: .horizontal)
                        repeat {
                            chain.add(cookie: cookies[column, row]!)
                            column += 1
                        } while column < NumColumns && cookies[column, row]?.cookieType == matchType
                        
                        set.insert(chain)
                        continue
                    }
                }
                //
                column += 1
            }
        }
        return set
    }
    //detect Vertical Matches
    private func detectVerticalMatches() -> Set<Chain> {
        var set = Set<Chain>()
        
        for column in 0..<NumColumns {
            var row = 0
            while row < NumRows-2 {
                if let cookie = cookies[column, row] {
                    let matchType = cookie.cookieType
                    
                    if cookies[column, row + 1]?.cookieType == matchType &&
                        cookies[column, row + 2]?.cookieType == matchType {
                        let chain = Chain(chainType: .vertical)
                        repeat {
                            chain.add(cookie: cookies[column, row]!)
                            row += 1
                        } while row < NumRows && cookies[column, row]?.cookieType == matchType
                        
                        set.insert(chain)
                        continue
                    }
                }
                row += 1
            }
        }
        return set
    }
    
    //remove matches considering horizontal and vertical in the same time
    func removeMatches() -> Set<Chain> {
        let horizontalChains = detectHorizontalMatches()
        let verticalChains = detectVerticalMatches()
        
//        print("Horizontal matches: \(horizontalChains)")
//        print("Vertical matches: \(verticalChains)")
        //in model
        removeCookies(chains: horizontalChains)
        removeCookies(chains: verticalChains)
        //calculate the score
        calculateScores(for: horizontalChains)
        calculateScores(for: verticalChains)
        //并集
        return horizontalChains.union(verticalChains)
    }
    
    //the function of remove cookies from array in model
    private func removeCookies(chains: Set<Chain>) {
        for chain in chains {
            for cookie in chain.cookies {
                cookies[cookie.column, cookie.row] = nil
            }
        }
    }
    //the function of fill the hole
    func fillHoles() -> [[Cookie]] {
        //restore the level by columns
        var columns = [[Cookie]]()
        //loop throught columns from bottom to up
        for column in 0..<NumColumns {
            var array = [Cookie]()
            for row in 0..<NumRows {
                //remember the tile without cookie
                if tiles[column, row] != nil && cookies[column, row] == nil {
                    //
                    for lookup in (row + 1)..<NumRows {
                        if let cookie = cookies[column, lookup] {
                            //moves the cookie down to fill the hole
                            cookies[column, lookup] = nil
                            cookies[column, row] = cookie
                            cookie.row = row
                            //add the cookie to array and cookies that are lower on the screen are first in the array
                            array.append(cookie)
                            //Once you’ve found a cookie, you don’t need to scan up any farther so you break out of the inner loop
                            break
                        }
                    }
                }
            }
            //
            if !array.isEmpty {
                columns.append(array)
            }
        }
        //returns an array containing all the cookies that have been moved down, organized by column.
        return columns
    }
    //add new cookies in the top of colum
    func topUpCookies() -> [[Cookie]] {
        var columns = [[Cookie]]()
        var cookieType: CookieType = .unknown
        //loop throught the column from top to bottoms
        for column in 0..<NumColumns {
            var array = [Cookie]()
            
            // 1
            var row = NumRows - 1
            while row >= 0 && cookies[column, row] == nil {
                //ignore the gap
                if tiles[column, row] != nil {
                    //new cookie type can't be equal to the type of the last new cookie
                    var newCookieType: CookieType
                    repeat {
                        newCookieType = CookieType.random()
                    } while newCookieType == cookieType
                    cookieType = newCookieType
                    //add the new cookie to the array
                    let cookie = Cookie(column: column, row: row, cookieType: cookieType)
                    cookies[column, row] = cookie
                    array.append(cookie)
                }
                
                row -= 1
            }
            // 5
            if !array.isEmpty {
                columns.append(array)
            }
        }
        return columns
    }
    //the function of calculating the score
    private func calculateScores(for chains: Set<Chain>) {
        // 3-chain is 60 pts, 4-chain is 120, 5-chain is 180, and so on
        for chain in chains {
            chain.score = 60 * (chain.length - 2) * comboMultiplier
            comboMultiplier += 1
        }
    }
    
    //reset the combo
    func resetComboMultiplier() {
        comboMultiplier = 1
    }
    init(filename: String) {
        //load the filename into dictionary(style of tile)
        guard let dictionary = Dictionary<String, AnyObject>.loadJSONFromBundle(filename: filename) else { return }
        // an array containing the columns for that row
        guard let tilesArray = dictionary["tiles"] as? [[Int]] else { return }
        //
        for (row, rowArray) in tilesArray.enumerated() {
            //reverse the order of rows
            let tileRow = NumRows - row - 1
            //creates a Tile object and places it into the tiles array
            for (column, value) in rowArray.enumerated() {
                if value == 1 {
                    tiles[column, tileRow] = Tile()
                }
            }
        }
        //parsed the JSON into a dictionary(score)
        targetScore = dictionary["targetScore"] as! Int
        maximumMoves = dictionary["moves"] as! Int
    }
}
