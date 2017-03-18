//
//  Array2D.swift
//  CookieCrunch
//
//  Created by xsf on 2017/3/15.
//  Copyright © 2017年 xsf. All rights reserved.
//

//create your own type that acts like a conventional 2D array
struct Array2D<T> {
    let columns: Int
    let rows: Int
    fileprivate var array: Array<T?>
    
    init(columns: Int, rows: Int) {
        self.columns = columns
        self.rows = rows
        //possible to be optional
        array = Array<T?>(repeating: nil,count: rows*columns)
    }
    
    subscript(column: Int, row: Int) -> T? {
        get {
            return array[row*columns + column]
        }
        set {
            array[row*columns + column] = newValue
        }
    }
}

