//
//  EthRPC.swift
//  pocket-aion
//
//  Created by Pabel Nunez Landestoy on 1/4/19.
//  Copyright © 2019 Pocket Network. All rights reserved.
//
// Structure that extends PocketAion with the ETH JSON RPC Methods with proper parsing.
// Usage: PocketAion.eth

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
        case estimateGas = "eth_estimateGas"
    }
    
    public struct eth {
        // Generic function to execute RPC methods and returns a BigInt
        private static func genericIntegerRPCMethod(subnetwork: String, params: [String], method: ethRPCMethodType, handler: @escaping PocketAionBigIntHandler) throws {
            
            let query = try PocketAion.createQuery(subnetwork: subnetwork, params: ["rpcMethod": method.rawValue, "rpcParams": params] as [String : Any], decoder: nil)
            
            PocketAion.shared.executeQuery(query: query) { (queryResponse, error) in
                if error != nil {
                    handler(nil, error)
                    return
                }
                
                if queryResponse == nil {
                    handler(nil, PocketPluginError.Aion.executionError("Query response is nil without errors"))
                    return
                }
                
                if queryResponse?.error == true {
                    handler(nil, PocketPluginError.Aion.executionError("\(queryResponse?.errorMsg ?? "Unknown query response error")"))
                    return
                }
                
                guard let txHash = queryResponse?.result?.value() as? String else {
                    handler(nil, PocketPluginError.queryCreationError("Failed to retrieve query response result value"))
                    return
                }
                guard let resultStr = HexStringUtil.removeLeadingZeroX(hex: txHash) else{
                    handler(nil, PocketPluginError.queryCreationError("Failed to remove leading zero from result string"))
                    return
                }
                
                let result = BigInt.init(resultStr, radix: 16)
                
                handler(result, nil)
                return
            }
        }
        
        // Generic function to execute RPC methods and returns an Array of String
        private static func genericStringRPCMethod(subnetwork: String,  params: [String], method: ethRPCMethodType, handler: @escaping PocketAionStringHandler) throws {
            
            let query = try PocketAion.createQuery(subnetwork: subnetwork, params: ["rpcMethod": method.rawValue, "rpcParams": params] as [String : Any], decoder: nil)
            
            PocketAion.shared.executeQuery(query: query) { (queryResponse, error) in
                if error != nil {
                    handler(nil, error)
                    return
                }
                
                if queryResponse == nil {
                    handler(nil, PocketPluginError.Aion.executionError("Query response is nil without errors"))
                    return
                }
                
                if queryResponse?.error == true {
                    handler(nil, PocketPluginError.Aion.executionError("\(queryResponse?.errorMsg ?? "Unknown query response error")"))
                    return
                }
                
                guard let txHash = queryResponse?.result?.value() as? String else {
                    handler(nil, PocketPluginError.queryCreationError("Failed to retrieve query response result value"))
                    return
                }
                
                handler([txHash], nil)
                return
            }
        }
        
        // Generic function to execute RPC methods and returns a [String: JSON] object
        private static func genericJSONRPCMethod(subnetwork: String, params: [String], method: ethRPCMethodType, handler: @escaping PocketAionJSONHandler) throws {
            
            let query = try PocketAion.createQuery(subnetwork: subnetwork, params: ["rpcMethod": method.rawValue, "rpcParams": params], decoder: nil)
            
            PocketAion.shared.executeQuery(query: query) { (queryResponse, error) in
                if error != nil {
                    handler(nil, error)
                    return
                }
                
                if queryResponse == nil {
                    handler(nil, PocketPluginError.Aion.executionError("Query response is nil without errors"))
                    return
                }
                
                if queryResponse?.error == true {
                    handler(nil, PocketPluginError.Aion.executionError("\(queryResponse?.errorMsg ?? "Unknown query response error")"))
                    return
                }
                
                guard let txHash = queryResponse?.result?.value() as? [String: JSON] else {
                    handler(nil, PocketPluginError.queryCreationError("Failed to retrieve query response result value"))
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
            let pos0 = HexStringUtil.prependZeroX(hex: position.toString(radix: 16))
            params.append(address)
            params.append(pos0)
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
        public static func call(from: String?, to: String, nrg: BigInt?, nrgPrice: BigInt?, value: BigInt?, data: String?, blockTag: BlockTag, subnetwork: String, handler: @escaping PocketAionStringHandler) throws {
            
            var txParams = [AnyHashable: Any]()
            let blockTagStr = blockTag.getBlockTagString()!
            
            if from != nil {
                txParams["from"] = from
            }else{
                txParams["from"] = ""
            }

            // Destination
            txParams["to"] = to
            
            if nrg != nil {
                txParams["nrg"] = HexStringUtil.prependZeroX(hex: nrg?.toString(radix: 16) ?? "0")
            }else{
                txParams["nrg"] = ""
            }
            if nrgPrice != nil {
                txParams["nrgPrice"] = HexStringUtil.prependZeroX(hex: nrgPrice?.toString(radix: 16) ?? "0")
            }else{
                txParams["nrgPrice"] = ""
            }
            if value != nil {
                txParams["value"] = HexStringUtil.prependZeroX(hex: value?.toString(radix: 16) ?? "0")
            }
            if data != nil {
                txParams["data"] = data
            }else{
                txParams["data"] = ""
            }
            
            let query = try PocketAion.createQuery(subnetwork: subnetwork, params: ["rpcMethod": PocketAion.ethRPCMethodType.call.rawValue, "rpcParams": [txParams, blockTagStr]], decoder: nil)
            
            PocketAion.shared.executeQuery(query: query) { (queryResponse, error) in
                if error != nil {
                    handler(nil, error)
                    return
                }
                
                if queryResponse == nil {
                    handler(nil, PocketPluginError.Aion.executionError("Query response is nil without errors"))
                    return
                }
                
                if queryResponse?.error == true {
                    handler(nil, PocketPluginError.Aion.executionError("\(queryResponse?.errorMsg ?? "Unknown query response error")"))
                    return
                }
                
                guard let txHash = queryResponse?.result?.value() as? String else {
                    let error = PocketPluginError.queryCreationError("Failed to retrieve query response result value")
                    
                    handler(nil, error)
                    return
                }
                
                handler([txHash], nil)
                return
            }
        }
        // eth_sendTransaction, returns a hash string
        public static func sendTransaction(wallet: Wallet, nonce: BigInt, to: String, data: String, value: BigInt, nrgPrice: BigInt, nrg: BigInt, handler: @escaping PocketAionStringHandler) throws {
            
            var txParams = [AnyHashable: Any]()
            txParams["nonce"] = nonce.toString(radix: 16)
            txParams["to"] = to
            txParams["data"] = data
            txParams["value"] = value.toString(radix: 16)
            txParams["nrgPrice"] = nrgPrice.toString(radix: 16)
            txParams["nrg"] = nrg.toString(radix: 16)
            
            let transaction = try createTransaction(wallet: wallet, params: txParams)
            
            PocketAion.shared.sendTransaction(transaction: transaction) { (txResponse, error) in
                if error != nil {
                    handler(nil, error)
                }else if txResponse?.error == true{
                    handler(nil,PocketPluginError.Aion.executionError("Send Transaction failed with error: \(txResponse?.errorMsg ?? "unkown")"))
                }else if txResponse != nil{
                    if txResponse?.hash != nil {
                        handler([(txResponse?.hash)!], nil)
                    }else {
                        handler(nil,PocketPluginError.Aion.executionError("Transaction response hash is nil, unknown error"))
                    }
                }else {
                    handler(nil,PocketPluginError.Aion.executionError("Send Transaction failed with unknown error"))
                }
            }
            
        }
        
        // eth_getBlockByHash, returns a [String: JSON] object with the information of a block by hash.
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
        // eth_getBlockByNumber, returns a [String: JSON] object with the information of a block by number.
        public static func getBlockByNumber(blockTag: BlockTag, fullTx: Bool, subnetwork: String, handler: @escaping PocketAionJSONHandler) throws {
            
            var params = [String]()
            params.append(blockTag.getBlockTagString()!)
            params.append(fullTx.description)
            
            try genericJSONRPCMethod(subnetwork: subnetwork, params: params, method: PocketAion.ethRPCMethodType.getBlockByNumber, handler: { (result, error) in
                if error != nil {
                    handler(nil, error)
                }else {
                    handler(result, error)
                }
            })
        }
        // eth_getTransactionByHash, returns a [String: JSON] object with the information of a transaction by hash.
        public static func getTransactionByHash(txHash: String, subnetwork: String, handler: @escaping PocketAionJSONHandler) throws {
            
            let params = [txHash]
            
            try genericJSONRPCMethod(subnetwork: subnetwork, params: params, method: PocketAion.ethRPCMethodType.getTransactionByHash, handler: { (result, error) in
                if error != nil {
                    handler(nil, error)
                }else {
                    handler(result, error)
                }
            })
        }
        // eth_getTransactionByBlockHashAndIndex, returns a [String: JSON] object with the information of a transaction by hash and index.
        public static func getTransactionByBlockHashAndIndex(blockHash: String, index: BigInt, subnetwork: String, handler: @escaping PocketAionJSONHandler) throws {
            
            var params = [String]()
            params.append(blockHash)
            params.append(index.toString(radix: 16))
            
            try genericJSONRPCMethod(subnetwork: subnetwork, params: params, method: PocketAion.ethRPCMethodType.getTransactionByBlockHashAndIndex, handler: { (result, error) in
                if error != nil {
                    handler(nil, error)
                }else {
                    handler(result, error)
                }
            })
        }
        // eth_getTransactionByBlockNumberAndIndex, returns a [String: JSON] object with the information of a transaction by number and index.
        public static func getTransactionByBlockNumberAndIndex(blockTag: BlockTag, index: BigInt, subnetwork: String, handler: @escaping PocketAionJSONHandler) throws {
            
            var params = [String]()
            params.append(HexStringUtil.prependZeroX(hex: blockTag.getBlockTagString()!))
            params.append(index.toString(radix: 16))
            
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
        
        // eth_getLogs, Returns an array of all logs matching a given filter object as a JSON array.
        public static func getLogs(fromBlock: BlockTag?, toBlock: BlockTag?, address: String?, topics: [String]?, blockhash: String?, subnetwork: String, handler: @escaping PocketAionJSONArrayHandler) throws {
            
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
        
        // eth_estimateGas
        public static func estimateGas(to: String, fromAddress: String?, nrg: BigInt?, nrgPrice: BigInt?, value: BigInt?, data: String?, subnetwork: String, blockTag: BlockTag, handler: @escaping PocketAionBigIntHandler) throws {
            
            var txParams = [AnyHashable: Any]()
            let blockTagStr = blockTag.getBlockTagString()!
            
            txParams["to"] = to
            
            if (fromAddress != nil) {
                txParams["from"] = fromAddress
            }
            if (nrg != nil) {
                txParams["nrg"] =  HexStringUtil.prependZeroX(hex: nrg!.toString(radix: 16))
            }
            if (nrgPrice != nil) {
                txParams["nrgPrice"] =  HexStringUtil.prependZeroX(hex: nrgPrice!.toString(radix: 16))
            }
            if (value != nil) {
                txParams["value"] =  HexStringUtil.prependZeroX(hex: value!.toString(radix: 16))
            }
            if (data != nil) {
                txParams["data"] = data
            }
            
            let query = try PocketAion.createQuery(subnetwork: subnetwork, params: ["rpcMethod": PocketAion.ethRPCMethodType.estimateGas.rawValue, "rpcParams": [txParams, blockTagStr]], decoder: nil)
            
            PocketAion.shared.executeQuery(query: query) { (queryResponse, error) in
                if error != nil {
                    handler(nil, error)
                    return
                }
                
                if queryResponse == nil {
                    handler(nil, PocketPluginError.Aion.executionError("Query response is nil without errors"))
                    return
                }
                
                if queryResponse?.error == true {
                    handler(nil, PocketPluginError.Aion.executionError("\(queryResponse?.errorMsg ?? "Unknown query response error")"))
                    return
                }
                
                guard let txHash = queryResponse?.result?.value() as? String else {
                    let error = PocketPluginError.queryCreationError("Failed to retrieve query response result value")
                    
                    handler(nil, error)
                    return
                }
                
                guard let resultStr = HexStringUtil.removeLeadingZeroX(hex: txHash) else{
                    handler(nil, PocketPluginError.queryCreationError("Failed to remove leading zero from result string"))
                    return
                }
                
                let result = BigInt.init(resultStr, radix: 16)
                
                handler(result, nil)
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

