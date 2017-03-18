//
//  Extensions.swift
//  CookieCrunch
//
//  Created by xsf on 2017/3/16.
//  Copyright © 2017年 xsf. All rights reserved.
//

import Foundation
//add new methods to existing type
extension Dictionary {
    //load a JSON file from the app bundle, into a new dictionary of type Dictionary<String, AnyObject>. This means the dictionary’s keys are always strings but the associated values can be any type of object.
    static func loadJSONFromBundle(filename: String) -> Dictionary<String, AnyObject>? {
        var dataOK: Data
        var dictionaryOK: NSDictionary = NSDictionary()
        if let path = Bundle.main.path(forResource: filename, ofType: "json") {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: path), options: NSData.ReadingOptions()) as Data!
                dataOK = data!
            }
            catch {
                print("Could not load level file: \(filename), error: \(error)")
                return nil
            }
            do {
                //The method simply loads the specified file into an NSData object and then converts that to a Dictionary using the NSJSONSerialization API. This is mostly boilerplate code that you’ll find in any app that deals with JSON files.
                let dictionary = try JSONSerialization.jsonObject(with: dataOK, options: JSONSerialization.ReadingOptions()) as AnyObject!
                dictionaryOK = (dictionary as! NSDictionary as? Dictionary<String, AnyObject>)! as NSDictionary
            }
            catch {
                print("Level file '\(filename)' is not valid JSON: \(error)")
                return nil
            }
        }
        return dictionaryOK as? Dictionary<String, AnyObject>
    }
}
