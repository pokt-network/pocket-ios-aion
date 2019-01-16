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
    private var contractJSON: [JSON]
    private var schemaVersion: String?
    private var contractAddress: String
    private var subnetwork: String
    private var functions = [Function]()
    
    // Constants
    private static let SUPPORTED_SCHEMA_VERSION = "2.0.0";
    
    // JSON keys
    private static let ABI_KEY = "abi";
    private static let SCHEMA_VERSION_KEY = "schemaVersion";
    private static let FUNCTION_TYPE_KEY = "function";
    
    init(pocketAion: PocketAion, contractJSON: [JSON], schemaVersion: String, contractAddress: String, subnetwork: String) throws {
        self.pocketAion = pocketAion
        self.contractJSON = contractJSON
        self.schemaVersion = schemaVersion
        self.contractAddress = contractAddress
        self.subnetwork = subnetwork
        
        if try getSchemaVersion() != AionContract.SUPPORTED_SCHEMA_VERSION {
            throw PocketPluginError.Aion.executionError("Unsupported schema version, please use schemaVersion: \(AionContract.SUPPORTED_SCHEMA_VERSION)")
        }
        try parseContractFunctions()
    }
    
    public func executeConstantFunction(functionName: String, fromAdress: String, functionParams: [String], nrg: BigInt, nrgPrice: BigInt, value: BigInt, handler: @escaping PocketAionAnyHandler) throws {
        
        let function = getFunctionFromArray(name: functionName, functions: functions)
        
        if function == nil || function?.isConstant() == false {
            handler(nil, PocketPluginError.Aion.executionError("Invalid function name or function is not constant"))
        }
        
        let data = try function?.getEncodedFunctionCall(params: functionParams)
        
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
    public static func encodeFunctionCall(function: Function, params: [String]) throws -> String{
        // Convert parameters to string
        guard let functionJSONStr = function.getFunctionJSONString() else{
            throw PocketPluginError.Aion.executionError("Failed to retrieve function json string.")
        }
        guard let functionParamsStr = String.join(char: ",", array: params) else{
            throw PocketPluginError.Aion.executionError("Failed to retrieve function params.")
        }
        
        let encodedFunction = try PocketAion.encodeFunction(functionStr: functionJSONStr, params: functionParamsStr)
        
        return encodedFunction
    }
    
    public func getJSParams(params: [Any]) -> [String]?{
        var results = [Any]()
        var resultStrArray = [String]()
        
        for objParam in params {
            var currStr: String?
            
            if let objParamArray = objParam as? [Any]{
                let objStrings = self.objectsAsStrings(objParams: objParamArray)
                guard let result = String.join(char: ",", array: objStrings) else{
                    return nil
                }
                currStr = "[\(result)]"
            } else{
                currStr = self.objectAsString(objParam: objParam)
            }
            results.append(currStr ?? "")
        }
        
        for item in results {
            resultStrArray.append(item as? String ?? "")
        }
        
        return resultStrArray
    }
    
    private func objectsAsStrings(objParams: [Any]) ->[String]{
        var result = [String]()
        
        for objParam in objParams {
            if let objParamStr = objectAsString(objParam: objParam) {
                result.append(objParamStr)
            }
        }
        return result
    }
    
    private func objectAsString(objParam: Any) -> String?{
        var currStr = ""
        
        if objParam is Bool ||
            objParam is Double ||
            objParam is Float ||
            objParam is Int ||
            objParam is Int64 ||// long
            objParam is UInt8 ||// byte
            objParam is Int16// short
            {
                guard let strValue = objParam as? String else{
                    return nil
                }
                return strValue
        }else if objParam is String {
            currStr = "\"\(objParam)\""
        }else if objParam is BigInt {
            let objParamString = (objParam as! BigInt).toString(radix: 16)
            let formattedObjParam = HexStringUtil.prependZeroX(hex: objParamString)
            currStr = "\"\(formattedObjParam)\""
        }
        return currStr
    }
    
    private func parseContractFunctions() throws {
        var abi = [JSON]()
        
        for item in contractJSON {
            guard let jsonObj = item.dictionary else{
                return
            }
            guard let abiArray = jsonObj[AionContract.ABI_KEY]?.array else{
                return
            }
            
            abi = abiArray
        }
        
        for abiElement in abi {
            guard let function = try Function.parseFunctionElement(functionJSON: abiElement) else {
                return
            }
        
            functions.append(function)
        }
    }
    
    private func getSchemaVersion() throws -> String?{
        if schemaVersion == nil {
            guard let version = getStringByKeyFromJSONArray(key: AionContract.SCHEMA_VERSION_KEY, jsonArray: contractJSON) else {
                return nil
            }
            schemaVersion = version
        }
        
        return schemaVersion
    }

    public func getFunctionFromArray(name: String, functions: [Function]) -> Function?{
        for item in functions {
            if item.getName() == name {
                return item
            }
        }
        return nil
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

extension String {
    public static func join(char: String, array: [String]) -> String? {
        var result: String?
        
        for string in array {
            result?.append(string + char)
        }
        
        if (result?.isEmpty ?? true) == false {
            if String((result?.last)!) == char {
                result?.removeLast()
            }
        }
        
        return result
    }
}
