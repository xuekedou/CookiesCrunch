//
//  Cookie.swift
//  CookieCrunch
//
//  Created by xsf on 2017/3/15.
//  Copyright © 2017年 xsf. All rights reserved.
//

//this is a modal class that describe the data for the cookie
import SpriteKit
//cookie that is put into the set should conform to the Hashable protocol(fundemental concept)
enum CookieType : Int,CustomStringConvertible {
    //1:croissant...
    case unknown = 0, croissant, cupcake, danish, donut, macaroon, sugarCookie
    //return the sprite's name
    var spriteName: String {
        let spriteNames = [
            "Croissant",
            "Cupcake",
            "Danish",
            "Donut",
            "Macaroon",
            "SugarCookie"]
        
        return spriteNames[rawValue - 1]
    }
    //zoomed picture when tapped
    var highlightedSpriteName: String {
        return spriteName + "-Highlighted"
    }
    //get a random cookie type
    static func random() -> CookieType {
        //arc4random_uniform(6) generate a random number betwen 0 and 5 in type of UInt32
        return CookieType(rawValue: Int(arc4random_uniform(6)) + 1)!
    }
    //customize
    var description: String {
        return spriteName
    }
    
    
}
//Whenever you add the Hashable protocol to an object, you also need to supply the == comparison operator for comparing two objects of the same type.
func ==(lhs: Cookie, rhs: Cookie) -> Bool {
    return lhs.column == rhs.column && lhs.row == rhs.row
}
//CustomStringConvertible is a protocal to customize the output of when you print a cookie
class Cookie : CustomStringConvertible,Hashable {
    //keep track of cookies' position in 2D grid
    var column: Int
    var row: Int
    
    let cookieType: CookieType
    var sprite: SKSpriteNode?
    
    //hashable value 
    //This should return an Int value that is as unique as possible for your object
    var hashValue : Int {
        return row*10 + column
    }

    init(column: Int, row: Int, cookieType: CookieType) {
        self.column = column
        self.row = row
        self.cookieType = cookieType
    }
    //mix the type and square to description
    var description: String {
        return "type:\(cookieType) square:(\(column),\(row))"
    }
}
