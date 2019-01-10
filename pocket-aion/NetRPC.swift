//
//  NetRPC.swift
//  pocket-aion
//
//  Created by Pabel Nunez Landestoy on 1/4/19.
//  Copyright © 2019 Pocket Network. All rights reserved.
//

import Foundation
import Pocket
import BigInt

extension PocketAion {
    enum netRPCMethodType: String {
        case version = "net_version"
        case listening = "net_listening"
        case peerCount = "net_peerCount"
    }
    
    struct net {
        // Generic function to execute RPC methods and returns an Array of String
        private static func genericStringNetRPCMethod(subnetwork: String,  params: [String], method: netRPCMethodType, handler: @escaping PocketAionStringHandler) throws {
            
            let query = try PocketAion.createQuery(subnetwork: subnetwork, params: ["rpcMethod": method.rawValue, "rpcParams": params], decoder: nil)
            
            PocketAion.shared.executeQuery(query: query) { (queryResponse, error) in
                if error != nil {
                    handler(nil, error)
                    return
                }
                
                guard let txHash = queryResponse?.result?.value() as? [JSON] else {
                    let error = PocketPluginError.queryCreationError("Failed to retrieve query response result value")
                    
                    handler(nil, error)
                    return
                }
                
                guard let result = txHash.last?.value() as? String else {
                    let error = PocketPluginError.Aion.executionError("Failed to retrieve storage position raw value")
                    
                    handler(nil, error)
                    return
                }
                
                handler([result], nil)
                return
            }
        }
        // Generic function to execute RPC methods and returns a BigInt
        private static func genericIntegerRPCMethod(subnetwork: String, params: [String], method: netRPCMethodType, handler: @escaping PocketAionBigIntHandler) throws {
            
            let query = try PocketAion.createQuery(subnetwork: subnetwork, params: ["rpcMethod": method.rawValue, "rpcParams": params], decoder: nil)
            
            PocketAion.shared.executeQuery(query: query) { (queryResponse, error) in
                if error != nil {
                    handler(nil, error)
                    return
                }
                
                guard let txHash = queryResponse?.result?.value() as? [JSON] else {
                    let error = PocketPluginError.queryCreationError("Failed to retrieve query response result value")
                    
                    handler(nil, error)
                    return
                }
                
                let resultString = PocketAion.eth.jsonToString(json: txHash.last?.value() as Any)
                let result = BigInt(BigUInt.init(resultString)!)
                
                handler(result, nil)
                return
            }
        }
        
        // net_version, returns String - The current network id.
        public static func version(subnetwork: String, handler: @escaping PocketAionStringHandler) throws{
            try genericStringNetRPCMethod(subnetwork: subnetwork, params: [String](), method: PocketAion.netRPCMethodType.version, handler: { (result, error) in
                if error != nil {
                    handler(nil, error)
                }else {
                    handler(result, error)
                }
            })
        }
        // net_listening, returns Boolean - true when listening, otherwise false
        public static func listening(subnetwork: String, handler: @escaping PocketAionBooleanHandler) throws{
            try genericStringNetRPCMethod(subnetwork: subnetwork, params: [String](), method: PocketAion.netRPCMethodType.listening, handler: { (result, error) in
                if error != nil {
                    handler(nil, error)
                }else {
                    let bool = Bool.init(result?.first ?? "false")
                    handler(bool, error)
                }
            })
        }
        // net_peerCount, returns BigInt number of connected peers.
        public static func peerCount(subnetwork: String, handler: @escaping PocketAionBigIntHandler) throws{
            try genericIntegerRPCMethod(subnetwork: subnetwork, params: [String](), method: PocketAion.netRPCMethodType.peerCount, handler: { (result, error) in
                if error != nil {
                    handler(nil, error)
                }else {
                    handler(result, error)
                }
            })
        }
    }
}
