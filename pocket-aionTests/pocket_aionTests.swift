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
    }
    
    func testWalletValidity(wallet: Wallet) {
        XCTAssertNotNil(wallet)
        XCTAssertNotNil(wallet.address)
        XCTAssertNotNil(wallet.privateKey)
        XCTAssertNotNil(wallet.network)
        XCTAssertNotNil(wallet.subnetwork)
    }
    
    // Test for CreateWallet
    func testCreateWallet() {
        let wallet = try? PocketAion.createWallet(subnetwork: "mastery", data: nil)
        // Check wallet validity
        testWalletValidity(wallet: wallet!)
    }
    
    // Tests for importWallet()
    func testImportWallet() {
        let walletToImport = try? PocketAion.createWallet(subnetwork: "mastery", data: nil)
        let importedWallet = try? PocketAion.importWallet(privateKey: walletToImport?.privateKey ?? "", subnetwork: walletToImport?.subnetwork ?? "mastery", address: walletToImport?.address, data: walletToImport?.data)
        // Check wallet validity
        testWalletValidity(wallet: importedWallet!)
        
        // Compare walletToImport with the importeWallet
        XCTAssertEqual(walletToImport?.privateKey, importedWallet?.privateKey)
        XCTAssertEqual(walletToImport?.address, importedWallet?.address)
        XCTAssertEqual(walletToImport?.network, importedWallet?.network)
        XCTAssertEqual(walletToImport?.subnetwork, importedWallet?.subnetwork)
    }
    
    // Tests for createTransaction()
    func testCreateTransactionSuccess() {
        // Create account for the receiver of the transaction
        let receiverAccount = try? PocketAion.createWallet(subnetwork: "mastery", data: nil)
        
        // Transaction params
        let txParams = ["nonce": "1", "to": receiverAccount?.address ?? "", "data": "", "value": "0x989680", "gasPrice": "0x989680", "gas": "0x989680"]
        
        // Create account
        let account = try? PocketAion.createWallet(subnetwork: "mastery", data: nil)
        // Transaction
        let signedTx = try? PocketAion.createTransaction(wallet: account!, params: txParams)
        
        // Verify signed transaction data
        XCTAssertNotNil(signedTx)
        XCTAssertNotNil(signedTx?.serializedTransaction)
        XCTAssertEqual("AION", signedTx?.network)
        XCTAssertEqual("mastery", signedTx?.subnetwork)
    }
    
    func testCreateTransactionTOError() {
        let wallet = try? PocketAion.createWallet(subnetwork: "mastery", data: nil)
        
        var params = [AnyHashable : Any]()
        params["to"] = nil
        
        XCTAssertThrowsError(try PocketAion.createTransaction(wallet: wallet!, params: params))
    }
    
    // Tests for createQuery()
    func testCreateQuerySuccess() {
        let query = try? PocketAion.createQuery(subnetwork: "mastery", params: ["rpcMethod": "eth_getTransactionCount", "rpcParams": ["0x0", "latest"]], decoder: nil)
        XCTAssertNotNil(query)
        XCTAssertNotNil(query?.data)
        XCTAssertEqual(query?.network, "AION")
        XCTAssertEqual(query?.subnetwork, "mastery")
        XCTAssertNotNil(query?.decoder)
    }
    
    func testCreateQueryRPCError() {
        XCTAssertThrowsError(try PocketAion.createQuery(subnetwork: "mastery", params: ["failedKey": "failedValue"], decoder: nil))
    }

    // MARK: Performance tests
    func testCreateWalletPerformance() {
        self.measure {
            testCreateWallet()
        }
    }
    
    func testImportWalletPerformance() {
        self.measure {
            testImportWallet()
        }
    }
    
    func testCreateTransactionSuccessPerformance() {
        self.measure {
            testCreateTransactionSuccess()
        }
    }
    
    func testCreateQuerySuccessPerformance() {
        self.measure {
            testCreateQuerySuccess()
        }
    }

}
