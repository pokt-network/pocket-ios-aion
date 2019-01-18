//
//  AionContract.swift
//  pocket-aion
//
//  Created by Pabel Nunez Landestoy on 1/11/19.
//  Copyright © 2019 Pocket Network. All rights reserved.
//

import Foundation
import SwiftyJSON
import BigInt
import enum Pocket.PocketPluginError
import struct Pocket.Wallet

public class AionContract {
    
    private var pocketAion: PocketAion
    private var abiDefinition: [JSON]
    private var contractAddress: String
    private var subnetwork: String
    private var functions = [Function]()
    
    init(pocketAion: PocketAion, abiDefinition: [JSON], contractAddress: String, subnetwork: String) throws {
        self.pocketAion = pocketAion
        self.abiDefinition = abiDefinition
        self.contractAddress = contractAddress
        self.subnetwork = subnetwork
        
        try parseContractFunctions()
    }
    
    public func executeConstantFunction(functionName: String, fromAdress: String, functionParams: [Any], nrg: BigInt, nrgPrice: BigInt, value: BigInt, handler: @escaping PocketAionAnyHandler) throws {
        
        if functions.isEmpty {
            handler(nil, PocketPluginError.Aion.executionError("Failed to get functions from abi definition"))
        }
        
        guard let function = getFunctionFromArray(name: functionName, functions: functions) else {
            handler(nil, PocketPluginError.Aion.executionError("Failed to get functions from abi definition"))
            return
        }
        
        if function.isConstant() == false {
            handler(nil, PocketPluginError.Aion.executionError("Invalid function name or function is not constant"))
            return
        }
        
        let data = try function.getEncodedFunctionCall(params: functionParams)
        
        try PocketAion.eth.call(from: nil, to: contractAddress, gas: nrg, gasPrice: nrgPrice, value: value, data: data, blockTag: BlockTag.init(block: .LATEST), subnetwork: subnetwork) { (result, error) in
            if error != nil {
                handler(nil,error)
            }else if result != nil {
                handler(result,nil)
            }
        }
    }
    
    public func executeFunction(functionName: String, wallet: Wallet, functionParams: [String], nonce: BigInt?, nrg: BigInt, nrgPrice: BigInt, value: BigInt, handler: @escaping PocketAionStringHandler) throws{
        
        guard let function = getFunctionFromArray(name: functionName, functions: functions) else {
            handler(nil, PocketPluginError.Aion.executionError("Invalid function name"))
            return
        }
        
        let data = try function.getEncodedFunctionCall(params: functionParams)
        
        if nonce != nil {
            try PocketAion.eth.sendTransaction(wallet: wallet, nonce: nonce!, to: contractAddress, data: data, value: value, gasPrice: nrgPrice, gas: nrg) { (result, error) in
                if error != nil {
                    handler(nil,error)
                }else if result != nil {
                    handler(result,nil)
                }
            }
        }else {
            try PocketAion.eth.getTransactionCount(address: wallet.address, subnetwork: subnetwork, blockTag: BlockTag.init(block: .LATEST), handler: { (result, error) in
                if error != nil {
                    handler(nil,error)
                }else if result != nil {
                    guard let resultStr = result?.toString(radix: 16) else {
                        handler(nil,PocketPluginError.Aion.executionError("Failed to convert result"))
                        return
                    }
                    handler([resultStr],nil)
                }
            })
        }
        
    }
    
    // MARK: Tools
    private static func encodeFunction(functionStr: String, params: String) throws -> String{
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
    
    public static func encodeFunctionCall(function: Function, params: [Any]) throws -> String{
        // Convert parameters to string
        
        guard let functionJSONStr = function.getFunctionJSONString() else{
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
    
    private func parseContractFunctions() throws {

        for abiElement in abiDefinition {
            guard let function = try Function.parseFunctionElement(functionJSON: abiElement) else {
                return
            }
        
            functions.append(function)
        }
    }

    private func getFunctionFromArray(name: String, functions: [Function]) -> Function?{
        for item in functions {
            if item.getName() == name {
                return item
            }
        }
        return nil
    }
    
}

extension String {
    public static func join(char: Character, array: [String]) -> String? {
        var result = ""
        
        for string in array {
            result.append(string + String(char))
        }
        
        if result.last == char {
            result.removeLast()
        }
        
        return result
    }
}
