//
//  EthRPC.swift
//  pocket-aion
//
//  Created by Pabel Nunez Landestoy on 1/4/19.
//  Copyright © 2019 Pocket Network. All rights reserved.
//

import Foundation
import Pocket
import BigInt

// eth Struct

extension PocketAion {
    
    enum ethRPCMethodType: String {
        case getBalance = "eth_getBalance"
        case getStorageAt = "eth_getStorageAt"
        case getTransactionCount = "eth_getTransactionCount"
        case getBlockTransactionCountByHash = "eth_getBlockTransactionCountByHash"
        case getBlockTransactionCountByNumber = "eth_getBlockTransactionCountByNumber"
        case getUncleCountByBlockHash = "eth_getUncleCountByBlockHash"
        case getUncleCountByBlockNumber = "eth_getUncleCountByBlockNumber"
        case getCode = "eth_getCode"
        case call = "eth_call"
        case getBlockByHash = "eth_getBlockByHash"
        case getBlockByNumber = "eth_getBlockByNumber"
        case getTransactionByHash = "eth_getTransactionByHash"
        case getTransactionByBlockHashAndIndex = "eth_getTransactionByBlockHashAndIndex"
        case getTransactionByBlockNumberAndIndex = "eth_getTransactionByBlockNumberAndIndex"
        case getTransactionReceipt = "eth_getTransactionReceipt"
        case getUncleByBlockHashAndIndex = "eth_getUncleByBlockHashAndIndex"
        case getUncleByBlockNumberAndIndex = "eth_getUncleByBlockNumberAndIndex"
        case newBlockFilter = "eth_newBlockFilter"
        case newPendingTransactionFilter = "eth_newPendingTransactionFilter"
        case getFilterChanges = "eth_getFilterChanges"
        case getFilterLogs = "eth_getFilterLogs"
        case getWork = "eth_getWork"
        case getLogs = "eth_getLogs"
        case getProof = "eth_getProof"
    }
    
    struct eth {
        // Generic function to execute RPC methods and returns a BigInt
        private static func genericIntegerRPCMethod(subnetwork: String, params: [String], method: ethRPCMethodType, handler: @escaping PocketAionBigIntHandler) throws {
            
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
                
                let resultString = jsonToString(json: txHash.last?.value() as Any)
                let result = BigInt(BigUInt.init(resultString)!)
                
                handler(result, nil)
                return
            }
        }
        
        // Generic function to execute RPC methods and returns an Array of String
        private static func genericStringRPCMethod(subnetwork: String,  params: [String], method: ethRPCMethodType, handler: @escaping PocketAionStringHandler) throws {
            
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
        
        // Generic function to execute RPC methods and returns an Array of JSON objects
        private static func genericJSONRPCMethod(subnetwork: String, params: [String], method: ethRPCMethodType, handler: @escaping PocketAionJSONHandler) throws {
            
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
                
                handler(txHash, nil)
                return
            }
        }
        
        // eth_getBalance, returns a Bigint of the current balance in wei.
        public static func getBalance(address: String, subnetwork: String, blockTag: BlockTag, handler: @escaping PocketAionBigIntHandler) throws {
            
            var params = [String]()
            params.append(address)
            params.append(blockTag.getBlockTagString()!)
            
            try genericIntegerRPCMethod(subnetwork: subnetwork, params: params, method: PocketAion.ethRPCMethodType.getBalance) { (result, error) in
                if error != nil {
                    handler(nil, error)
                }else {
                    handler(result, error)
                }
            }
        }
        
        // eth_getTransactionCount, returns a Bigint number of transactions send from this address.
        public static func getTransactionCount(address: String, subnetwork: String, blockTag: BlockTag, handler: @escaping PocketAionBigIntHandler) throws {
            
            var params = [String]()
            params.append(address)
            params.append(blockTag.getBlockTagString()!)
            
            try genericIntegerRPCMethod(subnetwork: subnetwork,  params: params, method: PocketAion.ethRPCMethodType.getTransactionCount) { (result, error) in
                if error != nil {
                    handler(nil, error)
                }else {
                    handler(result, error)
                }
            }
        }
        
        // eth_getStorageAt, returns an hexadecimal string with the value at this storage position
        public static func getStorageAt(address: String, subnetwork: String, position: BigInt, blockTag: BlockTag, handler: @escaping PocketAionStringHandler) throws {
            
            var params = [String]()
            params.append(address)
            params.append(position.toString())
            params.append(blockTag.getBlockTagString()!)
            
            try genericStringRPCMethod(subnetwork: subnetwork, params: params, method: PocketAion.ethRPCMethodType.getStorageAt, handler: { (result, error) in
                if error != nil {
                    handler(nil, error)
                }else {
                    handler(result, error)
                }
            })
        }
        
        // eth_getBlockTransactionCountByHash, returns a BigInt number of transactions in this block.
        public static func getBlockTransactionCountByHash(blockHash: String, subnetwork: String, handler: @escaping PocketAionBigIntHandler) throws {
            
            let params = [blockHash]
            
            try genericIntegerRPCMethod(subnetwork: subnetwork,  params: params, method: PocketAion.ethRPCMethodType.getBlockTransactionCountByHash) { (result, error) in
                if error != nil {
                    handler(nil, error)
                }else {
                    handler(result, error)
                }
            }
        }

        // eth_getBlockTransactionCountByNumber, returns a BigInt number of transactions in this block.
        public static func getBlockTransactionCountByNumber(blockTag: BlockTag, subnetwork: String, handler: @escaping PocketAionBigIntHandler) throws {
            
            let params = [blockTag.getBlockTagString()!]
            
            try genericIntegerRPCMethod(subnetwork: subnetwork,  params: params, method: PocketAion.ethRPCMethodType.getBlockTransactionCountByNumber) { (result, error) in
                if error != nil {
                    handler(nil, error)
                }else {
                    handler(result, error)
                }
            }
        }
        
        // eth_getUncleCountByBlockHash, returns a BigInt number of uncles in this block.
        public static func getUncleCountByBlockHash(blockHash: String, subnetwork: String, handler: @escaping PocketAionBigIntHandler) throws {
            
            let params = [blockHash]
            
            try genericIntegerRPCMethod(subnetwork: subnetwork,  params: params, method: PocketAion.ethRPCMethodType.getUncleCountByBlockHash) { (result, error) in
                if error != nil {
                    handler(nil, error)
                }else {
                    handler(result, error)
                }
            }
        }
        
        // eth_getUncleCountByBlockNumber, returns a BigInt number of uncles in this block.
        public static func getUncleCountByBlockNumber(blockTag: BlockTag, subnetwork: String, handler: @escaping PocketAionBigIntHandler) throws {
            
            let params = [blockTag.getBlockTagString()!]
            
            try genericIntegerRPCMethod(subnetwork: subnetwork,  params: params, method: PocketAion.ethRPCMethodType.getUncleCountByBlockNumber) { (result, error) in
                if error != nil {
                    handler(nil, error)
                }else {
                    handler(result, error)
                }
            }
        }
        // eth_getCode, returns an string of the code from the given address.
        public static func getCode(address: String, subnetwork: String, blockTag: BlockTag, handler: @escaping PocketAionStringHandler) throws {
            
            var params = [String]()
            params.append(address)
            params.append(blockTag.getBlockTagString()!)
            
            try genericStringRPCMethod(subnetwork: subnetwork, params: params, method: PocketAion.ethRPCMethodType.getCode) { (result, error) in
                if error != nil {
                    handler(nil, error)
                }else {
                    handler(result, error)
                }
            }
        }
        // eth_call, returns an String with the value of executed contract.
        public static func call(from: String?, to: String, gas: BigInt?, gasPrice: BigInt?, value: BigInt?, data: String?, blockTag: BlockTag, subnetwork: String, handler: @escaping PocketAionStringHandler) throws {
            
            var txParams = [AnyHashable: Any]()
            let blockTagStr = blockTag.getBlockTagString()!
            
            if from != nil {
                txParams["from"] = from
            }
            if gas != nil {
                txParams["gas"] = gas?.toString()
            }
            if gasPrice != nil {
                txParams["gasPrice"] = gasPrice?.toString()
            }
            if value != nil {
                txParams["value"] = value?.toString()
            }
            if data != nil {
                txParams["data"] = data
            }
            
            let query = try PocketAion.createQuery(subnetwork: subnetwork, params: ["rpcMethod": PocketAion.ethRPCMethodType.call.rawValue, "rpcParams": [txParams, blockTagStr]], decoder: nil)
            
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
        // eth_getBlockByHash, returns an array of JSON objects with the information of a block by hash.
        public static func getBlockByHash(blockHash: String, fullTx: Bool, subnetwork: String, handler: @escaping PocketAionJSONHandler) throws {
            
            var params = [String]()
            params.append(blockHash)
            params.append(fullTx.description)
            
            try genericJSONRPCMethod(subnetwork: subnetwork, params: params, method: PocketAion.ethRPCMethodType.getBlockByHash, handler: { (result, error) in
                if error != nil {
                    handler(nil, error)
                }else {
                    handler(result, error)
                }
            })
        }
        // eth_getBlockByNumber, returns an array of JSON objects with the information of a block by number.
        public static func getBlockByNumber(blockTag: BlockTag, fullTx: Bool, subnetwork: String, handler: @escaping PocketAionJSONHandler) throws {
            
            var params = [String]()
            params.append(blockTag.getBlockTagString()!)
            params.append(fullTx.description)
            
            try genericJSONRPCMethod(subnetwork: subnetwork, params: params, method: PocketAion.ethRPCMethodType.getBlockByHash, handler: { (result, error) in
                if error != nil {
                    handler(nil, error)
                }else {
                    handler(result, error)
                }
            })
        }
        // eth_getTransactionByHash, returns an array of JSON objects with the information of a transaction by hash.
        public static func getTransactionByHash(txHash: String, subnetwork: String, handler: @escaping PocketAionJSONHandler) throws {
            
            let params = [txHash]
            
            try genericJSONRPCMethod(subnetwork: subnetwork, params: params, method: PocketAion.ethRPCMethodType.getBlockByHash, handler: { (result, error) in
                if error != nil {
                    handler(nil, error)
                }else {
                    handler(result, error)
                }
            })
        }
        // eth_getTransactionByBlockHashAndIndex, returns an array of JSON objects with the information of a transaction by hash and index.
        public static func getTransactionByBlockHashAndIndex(blockHash: String, index: BigInt, subnetwork: String, handler: @escaping PocketAionJSONHandler) throws {
            
            var params = [String]()
            params.append(blockHash)
            params.append(index.toString())
            
            try genericJSONRPCMethod(subnetwork: subnetwork, params: params, method: PocketAion.ethRPCMethodType.getTransactionByBlockHashAndIndex, handler: { (result, error) in
                if error != nil {
                    handler(nil, error)
                }else {
                    handler(result, error)
                }
            })
        }
        // eth_getTransactionByBlockNumberAndIndex, returns an array of JSON objects with the information of a transaction by number and index.
        public static func getTransactionByBlockNumberAndIndex(blockTag: BlockTag, index: BigInt, subnetwork: String, handler: @escaping PocketAionJSONHandler) throws {
            
            var params = [String]()
            params.append(blockTag.getBlockTagString()!)
            params.append(index.toString())
            
            try genericJSONRPCMethod(subnetwork: subnetwork, params: params, method: PocketAion.ethRPCMethodType.getTransactionByBlockNumberAndIndex, handler: { (result, error) in
                if error != nil {
                    handler(nil, error)
                }else {
                    handler(result, error)
                }
            })
        }
        // eth_getTransactionReceipt, returns a transaction receipt inside a JSON array as an object, or null when no receipt was found.
        public static func getTransactionReceipt(txHash: String, subnetwork: String, handler: @escaping PocketAionJSONHandler) throws {
            
            let params = [txHash]
            
            try genericJSONRPCMethod(subnetwork: subnetwork, params: params, method: PocketAion.ethRPCMethodType.getTransactionReceipt, handler: { (result, error) in
                if error != nil {
                    handler(nil, error)
                }else {
                    handler(result, error)
                }
            })
        }
        // eth_getUncleByBlockHashAndIndex, returns an array of JSON objects with the information of a block by hash and index.
        public static func getUncleByBlockHashAndIndex(blockHash: String, index: BigInt, subnetwork: String, handler: @escaping PocketAionJSONHandler) throws {
            
            var params = [String]()
            params.append(blockHash)
            params.append(index.toString())
            
            try genericJSONRPCMethod(subnetwork: subnetwork, params: params, method: PocketAion.ethRPCMethodType.getUncleByBlockHashAndIndex, handler: { (result, error) in
                if error != nil {
                    handler(nil, error)
                }else {
                    handler(result, error)
                }
            })
        }
        // eth_getUncleByBlockNumberAndIndex, returns an array of JSON objects with the information of a block by number and index.
        public static func getUncleByBlockNumberAndIndex(blockTag: BlockTag, index: BigInt, subnetwork: String, handler: @escaping PocketAionJSONHandler) throws {
            
            var params = [String]()
            params.append(blockTag.getBlockTagString()!)
            params.append(index.toString())
            
            try genericJSONRPCMethod(subnetwork: subnetwork, params: params, method: PocketAion.ethRPCMethodType.getUncleByBlockNumberAndIndex, handler: { (result, error) in
                if error != nil {
                    handler(nil, error)
                }else {
                    handler(result, error)
                }
            })
        }
        
        // eth_getLogs, Returns an array of all logs matching a given filter object as a JSON array.
        public static func getLogs(fromBlock: BlockTag?, toBlock: BlockTag?, address: String?, topics: [String]?, blockhash: String?, subnetwork: String, handler: @escaping PocketAionJSONHandler) throws {
            
            var params = [AnyHashable: Any]()
            
            if fromBlock != nil {
                params["fromBlock"] = fromBlock?.getBlockTagString()!
            }
            if toBlock != nil {
                params["toBlock"] = toBlock?.getBlockTagString()!
            }
            if address != nil {
                params["address"] = address
            }
            if topics != nil {
                params["topics"] = topics
            }
            if blockhash != nil {
                params["blockhash"] = blockhash
            }
            
            let query = try PocketAion.createQuery(subnetwork: subnetwork, params: ["rpcMethod": PocketAion.ethRPCMethodType.getLogs.rawValue, "rpcParams": [params]], decoder: nil)
            
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
                
                handler(txHash, nil)
                return
            }

        }
        // eth_getWork, returns the hash of the current block, the seedHash, and the boundary condition to be met ("target") as an array of Strings.
        public static func getWork(subnetwork: String, handler: @escaping PocketAionStringHandler) throws {
            
            try genericStringRPCMethod(subnetwork: subnetwork, params: [String](), method: PocketAion.ethRPCMethodType.getWork) { (result, error) in
                if error != nil {
                    handler(nil, error)
                }else {
                    handler(result, error)
                }
            }
        }
        
        // eth_getProof, returns the account- and storage-values of the specified account including the Merkle-proof as a JSON Object.
        public static func getProof(address: String, storageKeys: [String], blockTag: BlockTag, subnetwork: String, handler: @escaping PocketAionJSONHandler) throws {
            
            let block = blockTag.getBlockTagString()!
            
            let query = try PocketAion.createQuery(subnetwork: subnetwork, params: ["rpcMethod": PocketAion.ethRPCMethodType.getProof.rawValue, "rpcParams": [address, storageKeys, block]], decoder: nil)
            
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
                
                handler(txHash, nil)
                return
            }
            
        }
        
        // MARK: Tools
        public static func jsonToString(json: Any) -> String {
            do {
                let data =  try JSONSerialization.data(withJSONObject: json, options: JSONSerialization.WritingOptions.prettyPrinted)
                
                let convertedString = String(data: data, encoding: String.Encoding.utf8)
                return convertedString ?? ""
                
            } catch let myJSONError {
                print(myJSONError)
            }
            return ""
        }
    }
}

