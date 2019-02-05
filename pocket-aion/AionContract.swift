//
//  AionContract.swift
//  pocket-aion
//
//  Created by Pabel Nunez Landestoy on 1/11/19.
//  Copyright © 2019 Pocket Network. All rights reserved.
//
// AionContract abstracts the complexity of interacting with an smart contract 

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
    
    public init(pocketAion: PocketAion, abiDefinition: [JSON], contractAddress: String, subnetwork: String) throws {
        self.pocketAion = pocketAion
        self.abiDefinition = abiDefinition
        self.contractAddress = contractAddress
        self.subnetwork = subnetwork
        
        try parseContractFunctions()
    }
    
    public func executeConstantFunction(functionName: String, fromAdress: String?, functionParams: [Any], nrg: BigInt?, nrgPrice: BigInt?, value: BigInt?, handler: @escaping PocketAionAnyHandler) throws {
        
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
        
        let data = try function.encodeFunctionCall(params: functionParams)
        
        try PocketAion.eth.call(from: nil, to: contractAddress, nrg: nrg, nrgPrice: nrgPrice, value: value, data: data, blockTag: BlockTag.init(block: .LATEST), subnetwork: subnetwork) { (result, error) in
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
        
        let data = try function.encodeFunctionCall(params: functionParams)
        
        if nonce != nil {
            try PocketAion.eth.sendTransaction(wallet: wallet, nonce: nonce!, to: contractAddress, data: data, value: value, nrgPrice: nrgPrice, nrg: nrg) { (result, error) in
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
