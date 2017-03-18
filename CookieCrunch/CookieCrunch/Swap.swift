//
//  Swap.swift
//  CookieCrunch
//
//  Created by xsf on 2017/3/16.
//  Copyright © 2017年 xsf. All rights reserved.
//

struct Swap: CustomStringConvertible,Hashable {
    let cookieA: Cookie
    let cookieB: Cookie
    
    init(cookieA: Cookie, cookieB: Cookie) {
        self.cookieA = cookieA
        self.cookieB = cookieB
    }
    
    var description: String {
        return "swap \(cookieA) with \(cookieB)"
    }
    //implement protocal of Hashable
    //That’s a common trick to make hash values.(^)
    var hashValue: Int {
        return cookieA.hashValue ^ cookieB.hashValue
    }
    
}

//add the == function that required by Hashable protocal
func ==(lhs: Swap, rhs: Swap) -> Bool {
    return (lhs.cookieA == rhs.cookieA && lhs.cookieB == rhs.cookieB) ||
        (lhs.cookieB == rhs.cookieA && lhs.cookieA == rhs.cookieB)
}
