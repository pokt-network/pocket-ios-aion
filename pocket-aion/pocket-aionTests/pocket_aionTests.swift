//
//  pocket_aionTests.swift
//  pocket-aionTests
//
//  Created by Pabel Nunez Landestoy on 12/7/18.
//  Copyright © 2018 Pocket Network. All rights reserved.
//

import XCTest
import JavaScriptCore
@testable import Pocket
@testable import pocket_aion

class pocket_aionTests: XCTestCase {
    
    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        PocketAion.jsContext = JSContext()
    }

    func testCreateAndImportAccount() {

        // Initialize PocketAion JS
        PocketAion.initJS()
        var account: Wallet?
        
        if let _ = PocketAion.jsContext {
            // Create account
            do {
                account = try PocketAion.createWallet(subnetwork: "mastery", data: nil)
            } catch {
                print(error)
            }
            
            if account == nil {
                print("Account for import is nil")
                return
            }
            
            do {
                let importedWallet = try PocketAion.importWallet(privateKey: account!.privateKey, subnetwork: "mastery", address: account!.address, data: nil)
                print("Imported account = \(importedWallet)")
            } catch {
                print(error)
            }
            
        }else {
            print("Failed to retrieve JS Context")
        }
        
    }
    
    func testSignTransaction() {
        // Initialize PocketAion JS
        PocketAion.initJS()
        var unSignedTx = [AnyHashable: Any]()
        
        do {
            let receiverAccount = try PocketAion.createWallet(subnetwork: "mastery", data: nil)
            
            unSignedTx["nonce"] = "1"
            unSignedTx["chainId"] = "010101"
            unSignedTx["to"] = receiverAccount.address
            unSignedTx["data"] = ""
            unSignedTx["value"] = "0x989680"
            unSignedTx["gasPrice"] = "0x989680"
            unSignedTx["gas"] = "0x989680"
            
            if let _ = PocketAion.jsContext {
                // Create account
                do {
                    let account = try PocketAion.createWallet(subnetwork: "mastery", data: nil)
                    // Transaction
                    let signedTx = try PocketAion.createTransaction(wallet: account, params: unSignedTx)
                    print(signedTx)
                } catch {
                    print(error)
                }
            }else {
                print("No Js Context")
            }
            
        } catch {
            print("Failed to create receiver wallet")
        }
        
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
