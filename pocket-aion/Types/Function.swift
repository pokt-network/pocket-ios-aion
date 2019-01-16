//
//  Function.swift
//  pocket-aion
//
//  Created by Pabel Nunez Landestoy on 1/14/19.
//  Copyright © 2019 Pocket Network. All rights reserved.
//

import Foundation
import SwiftyJSON
import enum Pocket.PocketPluginError

public struct Function {
    private var constant: Bool
    private var inputs: [InputOutput]
    private var name: String
    private var outputs: [InputOutput]
    private var payable: Bool
    private var stateMutability: String
    private var functionJSON: [AnyHashable: Any]
    
    // Constants
    private static let CONSTANT_KEY = "constant";
    private static let INPUTS_KEY = "inputs";
    private static let NAME_KEY = "name";
    private static let OUTPUTS_KEY = "outputs";
    private static let PAYABLE_KEY = "payable";
    private static let STATE_MUTABILITY_KEY = "stateMutability";
    private static let TYPE_KEY = "type";
    private static let FUNCTION_TYPE_VALUE = "function";
    
    init(constant: Bool, inputs: [InputOutput], name: String, outputs: [InputOutput], payable: Bool, stateMutability: String, functionJSON: [AnyHashable: Any]) {
        self.constant = constant
        self.inputs = inputs
        self.name = name
        self.outputs = outputs
        self.payable = payable
        self.stateMutability = stateMutability
        self.functionJSON = functionJSON
    }
    
    public static func parseFunctionElement(functionJSON: JSON ) throws -> Function? {

        guard let jsonObject = functionJSON.dictionaryObject else{
            return nil
        }
    
        if jsonObject[TYPE_KEY] as? String != FUNCTION_TYPE_VALUE {
            return nil
        }
        
        guard let constant = jsonObject[CONSTANT_KEY] as? String else{
            return nil
        }
        
        guard let inputsArray = jsonObject[INPUTS_KEY] as? [JSON] else {
            return nil
        }
        
        let inputs = try InputOutput.fromInputJSONArray(inputArrayJSON: inputsArray)
        
        guard let name = jsonObject[INPUTS_KEY] as? String else {
            return nil
        }
        
        guard let outputsArray = jsonObject[OUTPUTS_KEY] as? [JSON] else {
            return nil
        }
        
        let outputs = try InputOutput.fromInputJSONArray(inputArrayJSON: outputsArray)
        
        guard let payable = jsonObject[PAYABLE_KEY] as? String else {
            return nil
        }
        
        guard let stateMutability = jsonObject[STATE_MUTABILITY_KEY] as? String else {
            return nil
        }
        
        guard let functionObj = functionJSON.dictionaryObject else {
            return nil
        }
        
        return Function.init(constant: Bool.init(constant) ?? false, inputs: inputs, name: name, outputs: outputs, payable: Bool.init(payable) ?? false, stateMutability: stateMutability, functionJSON: functionObj)
    }
    
    public func isConstant() ->Bool {
        return constant;
    }
    
    public func getInputs() -> [InputOutput]{
        return inputs;
    }
    
    public func getName() -> String{
        return name;
    }
    
    public func getOutputs() -> [InputOutput]{
        return outputs;
    }
    
    public func isPayable() -> Bool{
        return payable;
    }
    
    public func getStateMutability() -> String {
        return stateMutability;
    }
    
    public func getFunctionJSON() -> [AnyHashable: Any]{
        return self.functionJSON;
    }
    
    public func getFunctionJSONString() -> String? {
        let json = JSON.init(self.functionJSON)
        
        guard let jsonString = json.rawString() else {
            return nil
        }
        
        return jsonString
    }
    
    public func getEncodedFunctionCall(params: [String]) throws ->String{

        let encodedFunction = try AionContract.encodeFunctionCall(function: self, params: params)
        
        return encodedFunction
    }
    
}
