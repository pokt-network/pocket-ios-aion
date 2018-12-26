//
//  PocketAion.swift
//  pocket-aion
//
//  Created by Pabel Nunez Landestoy on 12/12/18.
//  Copyright © 2018 Pocket Network. All rights reserved.
//

import Foundation
import Pocket
import JavaScriptCore

public class PocketAion: Pocket, PocketPlugin {
    
    public static var jsContext = JSContext()
    public static var network = "AION"
    
    public class func initJS() {
        // Retrieve and evaluate all javascript dependencies
        let cryptoPolyfillJS = getJSFileForResource(name: "crypto-polyfill")
        let promiseJs = getJSFileForResource(name: "promiseDeps")
        let distJS = getJSFileForResource(name: "Web3Aion")
        
        // Create window object
        jsContext?.evaluateScript("var window = this;")
        
        // Add crypto polyfill
        jsContext?.evaluateScript(cryptoPolyfillJS)
        
        // Add timeout and promises
        jsContext?.evaluateScript(promiseJs)
        
        // Add aion web3
        jsContext?.evaluateScript(distJS)
        
        // Create aion instance
        jsContext?.evaluateScript("var aionInstance = new AionWeb3();")
        
    }
    
    public static func createWallet(subnetwork: String, data: [AnyHashable : Any]?) throws -> Wallet {
        // Create account
        guard let account = jsContext?.evaluateScript("aionInstance.eth.accounts.create()")?.toObject() as? [AnyHashable: Any] else {
            throw PocketPluginError.walletCreationError("Failed to create account")
        }
        guard let privateKey = account["privateKey"] as? String else {
            throw PocketPluginError.walletCreationError("Invalid private key")
        }
        
        guard let address = account["address"] as? String else {
            throw PocketPluginError.walletCreationError("Invalid address")
        }
        
        return try Wallet(address: address, privateKey: privateKey, network: network, subnetwork: subnetwork, data: nil)
    }
    
    public static func importWallet(privateKey: String, subnetwork: String, address: String?, data: [AnyHashable : Any]?) throws -> Wallet {
        // Exception handler
        jsContext?.exceptionHandler = { context, error in
            print("JsContext failed with error: \(error?.toString() ?? "none")")
        }
        
        guard let publicKey = address else {
            throw PocketPluginError.walletCreationError("Invalid public key")
        }
        
        // JS Account
        guard let _ = jsContext?.evaluateScript("var account = aionInstance.eth.accounts.privateKeyToAccount('\(privateKey)')") else {
            throw PocketPluginError.transactionCreationError("Failed to create account js object")
        }
        
        guard let account = jsContext?.objectForKeyedSubscript("account")?.toObject() as? [AnyHashable: Any] else {
            throw PocketPluginError.transactionCreationError("Failed to create account object")
        }
        
        if account["address"] as? String != publicKey {
            throw PocketPluginError.transactionCreationError("Failed to create account object")
        }
        
        return try Wallet(address: publicKey, privateKey: privateKey, network: network, subnetwork: subnetwork, data: nil)
    }
    
    public static func createTransaction(wallet: Wallet, params: [AnyHashable : Any]) throws -> Transaction {
        // Pocket Transaction
        let pocketTx = Transaction(obj: ["network": wallet.network, "subnetwork": wallet.subnetwork])
        
        // JS Account
        guard let _ = jsContext?.evaluateScript("var account = aionInstance.eth.accounts.privateKeyToAccount('\(wallet.privateKey)')") else {
            throw PocketPluginError.transactionCreationError("Failed to create account object")
        }
        
        // Transaction params
        guard let nonce =  params["nonce"] as? String else {
            throw PocketPluginError.transactionCreationError("Failed to retrieve nonce")
        }
        
        guard let to =  params["to"] as? String else {
            throw PocketPluginError.transactionCreationError("Failed to retrieve the receiver of the transaction (to) ")
        }
        
        let data = params["data"] as? String
        
        guard let value =  params["value"] as? String else {
            throw PocketPluginError.transactionCreationError("Failed to retrieve value")
        }
        
        guard let gasPrice = params["gasPrice"] as? String else {
            throw PocketPluginError.transactionCreationError("Failed to retrieve gas price")
        }
        
        guard let gas =  params["gas"] as? String else {
            throw PocketPluginError.transactionCreationError("Failed to retrieve gas value")
        }
        
        // Exception handler
        jsContext?.exceptionHandler = { context, error in
            print("JsContext failed with error: \(error?.toString() ?? "none")")
        }
        
        // Promise Handler
        let promiseBlock: @convention(block) (JavaScriptCore.JSValue, JavaScriptCore.JSValue) -> () = { (error, result) in
            // Check for errors
            if !error.isNull {
                print("Failed to sign transaction with error: \(error)")
            }else{
                // Retrieve result object and raw transaction
                let resultObject = result.toObject() as! [AnyHashable: Any]
                
                guard let rawTx = resultObject["rawTransaction"] as? String else {
                    print("Failed to retrieve raw signed transaction")
                    return
                }
                // Assign pocket transaction value for property serializedTransaction
                pocketTx.serializedTransaction = rawTx
            }
        }
        
        // Create Window object from js value
        guard let window = jsContext?.objectForKeyedSubscript("window") else {
            throw PocketPluginError.transactionCreationError("Failed to retrieve window js object")
        }
        
        // Set the promise block handler to the transactionCreationCallback
        window.setObject(promiseBlock, forKeyedSubscript: "transactionCreationCallback" as NSString)
        
        // Retrieve SignTransaction JS File
        let signTxJSStr = getJSFileForResource(name: "SignTransaction")
        
        // Check if is empty and evaluate script with the transaction parameters using string format %@
        if !signTxJSStr.isEmpty {
            let string = String(format: signTxJSStr, nonce, to, value, data ?? "", gas, gasPrice, wallet.privateKey)
            jsContext?.evaluateScript(string)
        }else {
            throw PocketPluginError.transactionCreationError("Failed to retrieve signed tx js string")
        }
        
        // Clean global objects from context
        removeJSGlobalObjects()
        
        return pocketTx
    }
    
    public static func createQuery(subnetwork: String, params: [AnyHashable : Any], decoder: [AnyHashable : Any]?) throws -> Query {
        let pocketQuery = Query(network: network, subnetwork: subnetwork, data: nil, decoder: nil)
        
        // Create data param
        var queryParams = [AnyHashable: Any]()
        if let rpcMethod = params["rpcMethod"] as? String, let rpcParams = params["rpcParams"] as? [Any] {
            queryParams["rpc_method"] = rpcMethod
            queryParams["rpc_params"] = rpcParams
        } else {
            throw PocketPluginError.queryCreationError("Invalid RPC params")
        }
        
        pocketQuery.data = try JSON.valueToJsonPrimitive(anyValue: queryParams)
        
        // Create decoder param
        var decoderParams = [AnyHashable: Any]()
        if decoder != nil {
            if let returnTypes = decoder!["returnTypes"] as? [String] {
                decoderParams["return_types"] = returnTypes
            }
        }
        pocketQuery.decoder = try JSON.valueToJsonPrimitive(anyValue: decoderParams)
        
        // Assign network
        pocketQuery.network = network
        pocketQuery.subnetwork = subnetwork
        
        return pocketQuery
    }
    
    // MARK: Tools
    public static func removeJSGlobalObjects() {
        jsContext?.evaluateScript("window.transactionCreationCallback = ''")
        jsContext?.evaluateScript("account = ''")
    }
    
    public static func getJSFileForResource(name: String) -> String {
        guard let aionBundleURL = Bundle.init(for: PocketAion.self).url(forResource: "aion", withExtension: "bundle") else {
            return ""
        }
        
        guard let aionBundle = Bundle.init(url: aionBundleURL) else {
            return ""
        }
        
        do {
            let jsFilePath = aionBundle.path(forResource: name, ofType: "js")
            
            let jsFileString = try String(contentsOfFile: jsFilePath!, encoding: String.Encoding.utf8)
            
            return jsFileString
        } catch {
            print(error);
        }
        
        return ""
    }
    
}
