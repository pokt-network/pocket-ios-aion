//
//  InputOutput.swift
//  pocket-aion
//
//  Created by Pabel Nunez Landestoy on 1/15/19.
//  Copyright © 2019 Pocket Network. All rights reserved.
//

import Foundation
import SwiftyJSON
import enum Pocket.PocketPluginError

public struct InputOutput {
    private var name: String
    private var type: String
    
    // Constants
    private static let NAME_KEY = "name";
    private static let TYPE_KEY = "type";
    
    init(name: String, type: String) {
        self.name = name
        self.type = type
    }
    
    public static func fromInputJSONArray(inputArrayJSON: JSON) throws -> [InputOutput] {
        var result = [InputOutput]()
        for item in inputArrayJSON.array! {
            guard let inputOutput = try InputOutput.fromInputJSONObject(inputObj: item) else {
                throw PocketPluginError.Aion.executionError("Failed create inputOutput element from JSON Object")
            }
            result.append(inputOutput)
        }
        
        return result;
    }
    
    public static func fromInputJSONObject(inputObj: JSON) throws -> InputOutput? {
        
        let inputName = inputObj[NAME_KEY].stringValue
        let inputType = inputObj[TYPE_KEY].stringValue

        return InputOutput(name: inputName, type: inputType);
    }
    
    public func getName() -> String {
        return self.name;
    }
    
    public func getType() -> String {
        return self.type;
    }
    
}
