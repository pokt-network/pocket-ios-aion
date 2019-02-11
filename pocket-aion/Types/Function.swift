//
//  Function.swift
//  pocket-aion
//
//  Created by Pabel Nunez Landestoy on 1/14/19.
//  Copyright © 2019 Pocket Network. All rights reserved.
//
// Struct that handles the ABI Function elements and properties

import Foundation
import SwiftyJSON
import enum Pocket.PocketPluginError

public struct Function {
    private var constant: Bool
    private var inputs: [InputOutput]
    private var name: String
    private var outputs: [InputOutput]
    private var payable: Bool
    private var functionJSON: [AnyHashable: Any]
    
    // Constants
    private static let CONSTANT_KEY = "constant";
    private static let INPUTS_KEY = "inputs";
    private static let NAME_KEY = "name";
    private static let OUTPUTS_KEY = "outputs";
    private static let PAYABLE_KEY = "payable";
    private static let TYPE_KEY = "type";
    private static let FUNCTION_TYPE_VALUE = "function";
    
    public init(constant: Bool, inputs: [InputOutput], name: String, outputs: [InputOutput], payable: Bool, functionJSON: [AnyHashable: Any]) {
        self.constant = constant
        self.inputs = inputs
        self.name = name
        self.outputs = outputs
        self.payable = payable
        self.functionJSON = functionJSON
    }
    
    public static func parseFunctionElement(functionJSON: JSON ) throws -> Function? {

        guard let jsonObject = functionJSON.dictionaryObject else{
            return nil
        }
    
        if jsonObject[TYPE_KEY] as? String != FUNCTION_TYPE_VALUE {
            return nil
        }
        
        guard let constant = jsonObject[CONSTANT_KEY] as? Bool else{
            return nil
        }
    
        let inputsJSON = JSON.init(jsonObject[INPUTS_KEY] ?? [String: Any]())
        let inputs = try InputOutput.fromInputJSONArray(inputArrayJSON: inputsJSON)
        
        guard let name = jsonObject[NAME_KEY] as? String else {
            return nil
        }
        
        let outputsJSON = JSON.init(jsonObject[OUTPUTS_KEY] ?? [String: Any]())
        let outputs = try InputOutput.fromInputJSONArray(inputArrayJSON: outputsJSON)
        
        guard let payable = jsonObject[PAYABLE_KEY] as? Bool else {
            return nil
        }
        
        guard let functionObj = functionJSON.dictionaryObject else {
            return nil
        }
        
        return Function.init(constant: constant, inputs: inputs, name: name, outputs: outputs, payable: payable, functionJSON: functionObj)
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
    
    public func outputsASJSONString() -> String {
        var result: [JSON] = []
        self.outputs.forEach { (output) in
            result.append(output.getJSON())
        }
        
        guard let outputStr = JSON.init(result).rawString(.utf8) else {
            return "[]"
        }
        
        return outputStr
    }
    
    public func encodeFunctionCall(params: [Any]) throws -> String {
        // Convert parameters to string
        
        guard let functionJSONStr = self.getFunctionJSONString() else{
            throw PocketPluginError.Aion.executionError("Failed to retrieve function json string.")
        }
        
        guard let formattedRpcParams = RpcParamsUtil.formatRpcParams(params: params) else {
            throw PocketPluginError.Aion.executionError("Failed to format rpc params.")
        }
        
        guard let functionParamsStr = String.join(char: ",", array: formattedRpcParams) else{
            throw PocketPluginError.Aion.executionError("Failed to retrieve function params.")
        }
        
        let encodedFunction = try self.encodeFunction(functionStr: functionJSONStr, params: functionParamsStr)
        
        return encodedFunction
    }
    
    private func encodeFunction(functionStr: String, params: String) throws -> String{
        // TODO: Find a better way to do this
        try PocketAion.initJS()
        
        // Generate code to run
        guard let jsFile = try? PocketAion.getFileForResource(name: "encodeFunction", ext: "js") else{
            throw PocketPluginError.Aion.bundledFileError("Failed to retrieve encodeFunction.js file")
        }
        
        // Check if is empty and evaluate script with the transaction parameters using string format %@
        if !jsFile.isEmpty {
            let jsCode = String(format: jsFile, functionStr, params)
            // Evaluate js code
            PocketAion.jsContext?.evaluateScript(jsCode)
        }else {
            throw PocketPluginError.Aion.executionError("Failed to retrieve signed tx js string")
        }
        
        // Retrieve
        guard let functionCallData = PocketAion.jsContext?.objectForKeyedSubscript("functionCallData") else {
            throw PocketPluginError.Aion.executionError("Failed to retrieve window js object")
        }
        
        // return function call result
        return functionCallData.toString()
    }
    
    public func getStringByKeyFromJSONArray(key: String, jsonArray: [JSON]) -> String?{
        for item in jsonArray {
            guard let jsonObj = item.dictionary else{
                return nil
            }
            guard let result = jsonObj[key]?.string else{
                return nil
            }
            
            return result
        }
        return nil
    }
    
    public func getArrayByKeyFromJSONArray(key: String, jsonArray: [JSON]) -> [JSON]?{
        for item in jsonArray {
            guard let jsonObj = item.dictionary else{
                return nil
            }
            guard let array = jsonObj[key]?.array else{
                return nil
            }
            
            return array
        }
        return nil
    }
    
}
