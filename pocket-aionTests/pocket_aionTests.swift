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

class pocket_aionTests: XCTestCase, Configuration {
    public var nodeURL: URL {
        get {
            return URL(string: "https://aion.pokt.network")!
        }
    }
    
    public let subnetwork = "mastery"
    
    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        Pocket.shared.setConfiguration(config: self)
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
        let wallet = try? PocketAion.createWallet(subnetwork: subnetwork, data: nil)
        // Check wallet validity
        testWalletValidity(wallet: wallet!)
    }
    
    // Tests for importWallet()
    func testImportWallet() {
        let walletToImport = try? PocketAion.createWallet(subnetwork: subnetwork, data: nil)
        let importedWallet = try? PocketAion.importWallet(privateKey: walletToImport?.privateKey ?? "", subnetwork: walletToImport?.subnetwork ?? subnetwork, address: walletToImport?.address, data: walletToImport?.data)
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
        let receiverAccount = try? PocketAion.createWallet(subnetwork: subnetwork, data: nil)
        
        // Transaction params
        let txParams = ["nonce": "1", "to": receiverAccount?.address ?? "", "data": "", "value": "0x989680", "gasPrice": "0x989680", "gas": "0x989680"]
        
        // Create account
        let account = try? PocketAion.createWallet(subnetwork: subnetwork, data: nil)
        // Transaction
        let signedTx = try? PocketAion.createTransaction(wallet: account!, params: txParams)
        
        // Verify signed transaction data
        XCTAssertNotNil(signedTx)
        XCTAssertNotNil(signedTx?.serializedTransaction)
        XCTAssertEqual("AION", signedTx?.network)
        XCTAssertEqual(subnetwork, signedTx?.subnetwork)
    }
    
    func testCreateTransactionTOError() {
        let wallet = try? PocketAion.createWallet(subnetwork: subnetwork, data: nil)
        
        var params = [AnyHashable : Any]()
        params["to"] = nil
        
        XCTAssertThrowsError(try PocketAion.createTransaction(wallet: wallet!, params: params))
    }
    
    // Tests for createQuery()
    func testCreateQuerySuccess() {
        let query = try? PocketAion.createQuery(subnetwork: subnetwork, params: ["rpcMethod": "eth_getTransactionCount", "rpcParams": ["0x0", "latest"]], decoder: nil)
        XCTAssertNotNil(query)
        XCTAssertNotNil(query?.data)
        XCTAssertEqual(query?.network, "AION")
        XCTAssertEqual(query?.subnetwork, subnetwork)
        XCTAssertNotNil(query?.decoder)
    }
    
    func testCreateQueryRPCError() {
        XCTAssertThrowsError(try PocketAion.createQuery(subnetwork: subnetwork, params: ["failedKey": "failedValue"], decoder: nil))
    }
    
    // MARK: ETH RPC Tests
    func testGetBalanceSuccess() {
        guard let account = try? PocketAion.createWallet(subnetwork: subnetwork, data: nil) else {
            XCTFail("Failed to create account")
            return
        }
        
        // Create an expectation
        let expectation = self.expectation(description: "getBalance")
        
        try? PocketAion.eth.getBalance(address: account.address, subnetwork: subnetwork, blockTag: BlockTag.init(block: .LATEST), handler: { (result, error) in
            XCTAssertNil(error)
            XCTAssertNotNil(result)
            expectation.fulfill()
        })

        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testGetTransactionCount() {
        guard let account = try? PocketAion.createWallet(subnetwork: subnetwork, data: nil) else {
            XCTFail("Failed to create account")
            return
        }
        
        // Create an expectation
        let expectation = self.expectation(description: "getTransactionCount")
        
        try? PocketAion.eth.getTransactionCount(address: account.address, subnetwork: subnetwork, blockTag: BlockTag.init(block: .LATEST), handler: { (result, error) in
            XCTAssertNil(error)
            XCTAssertNotNil(result)
            expectation.fulfill()
        })
        
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testGetStorageAt() {
        guard let account = try? PocketAion.createWallet(subnetwork: subnetwork, data: nil) else {
            XCTFail("Failed to create account")
            return
        }
        
        // Create an expectation
        let expectation = self.expectation(description: "getStorageAt")
        
        try? PocketAion.eth.getStorageAt(address: account.address, subnetwork: subnetwork, position: 1234, blockTag: BlockTag.init(block: .LATEST), handler: { (results, error) in
            XCTAssertNil(error)
            XCTAssertNotNil(results)
            expectation.fulfill()
        })
        
        waitForExpectations(timeout: 4, handler: nil)
    }
    
    func testGetBlockTransactionCountByHash() {
        
        // Create an expectation
        let expectation = self.expectation(description: "getBlockTransactionCountByHash")
        
        try? PocketAion.eth.getBlockTransactionCountByHash(blockHash: "0x0", subnetwork: subnetwork, handler: { (result, error) in
            XCTAssertNil(error)
            XCTAssertNotNil(result)
            expectation.fulfill()
        })

        waitForExpectations(timeout: 4, handler: nil)
    }
    
    func testGetBlockTransactionCountByNumber() {
        // Create an expectation
        let expectation = self.expectation(description: "getBlockTransactionCountByNumber")
        
        try? PocketAion.eth.getBlockTransactionCountByNumber(blockTag: BlockTag.init(str: "1234"), subnetwork: subnetwork, handler: { (result, error) in
            XCTAssertNil(error)
            XCTAssertNotNil(result)
            expectation.fulfill()
        })
        
        waitForExpectations(timeout: 4, handler: nil)
    }
    
    func testGetUncleCountByBlockHash() {
        
        // Create an expectation
        let expectation = self.expectation(description: "getUncleCountByBlockHash")
        
        try? PocketAion.eth.getUncleCountByBlockHash(blockHash: "0x0", subnetwork: subnetwork, handler: { (result, error) in
            XCTAssertNil(error)
            XCTAssertNotNil(result)
            expectation.fulfill()
        })
        
        waitForExpectations(timeout: 4, handler: nil)
    }

    func testgetUncleCountByBlockNumber() {
        // Create an expectation
        let expectation = self.expectation(description: "getUncleCountByBlockNumber")
        
        try? PocketAion.eth.getUncleCountByBlockNumber(blockTag: BlockTag.init(str: "1234"), subnetwork: subnetwork, handler: { (result, error) in
            XCTAssertNil(error)
            XCTAssertNotNil(result)
            expectation.fulfill()
        })
        
        waitForExpectations(timeout: 4, handler: nil)
    }

    func testGetCode() {
        guard let account = try? PocketAion.createWallet(subnetwork: subnetwork, data: nil) else {
            XCTFail("Failed to create account")
            return
        }
        
        // Create an expectation
        let expectation = self.expectation(description: "getCode")
        
        try? PocketAion.eth.getCode(address: account.address, subnetwork: subnetwork, blockTag: BlockTag.init(block: .LATEST), handler: { (result, error) in
            XCTAssertNil(error)
            XCTAssertNotNil(result)
            expectation.fulfill()
        })

        waitForExpectations(timeout: 4, handler: nil)
    }

    func testCall() {
        guard let account = try? PocketAion.createWallet(subnetwork: subnetwork, data: nil) else {
            XCTFail("Failed to create account")
            return
        }
        
        // Create an expectation
        let expectation = self.expectation(description: "call")
        
        try? PocketAion.eth.call(from: nil, to: account.address, gas: 2000000000, gasPrice: 2000000000, value: 2000000000, data: nil, blockTag: BlockTag.init(block: .LATEST), subnetwork: subnetwork, handler: { (result, error) in
            XCTAssertNil(error)
            XCTAssertNotNil(result)
            expectation.fulfill()
        })

        waitForExpectations(timeout: 4, handler: nil)
    }

    func testGetBlockByHash() {
        
        // Create an expectation
        let expectation = self.expectation(description: "getBlockByHash")
        
        try? PocketAion.eth.getBlockByHash(blockHash: "0x0", fullTx: true, subnetwork: subnetwork, handler: { (result, error) in
            XCTAssertNil(error)
            XCTAssertNotNil(result)
            expectation.fulfill()
        })

        waitForExpectations(timeout: 4, handler: nil)
    }
    
    func testGetBlockByNumber() {
        
        // Create an expectation
        let expectation = self.expectation(description: "getBlockByNumber")
        
        try? PocketAion.eth.getBlockByNumber(blockTag: BlockTag.init(str: "1234"), fullTx: true, subnetwork: subnetwork, handler: { (result, error) in
            XCTAssertNil(error)
            XCTAssertNotNil(result)
            expectation.fulfill()
        })
        
        waitForExpectations(timeout: 4, handler: nil)
    }

    func testGetTransactionByHash() {
        
        // Create an expectation
        let expectation = self.expectation(description: "getTransactionByHash")
        
        try? PocketAion.eth.getTransactionByHash(txHash: "0x0", subnetwork: subnetwork, handler: { (result, error) in
            XCTAssertNil(error)
            XCTAssertNotNil(result)
            expectation.fulfill()
        })
        
        waitForExpectations(timeout: 4, handler: nil)
    }

    func testGetTransactionByBlockHashAndIndex() {
        
        // Create an expectation
        let expectation = self.expectation(description: "getTransactionByBlockHashAndIndex")
        
        try? PocketAion.eth.getTransactionByBlockHashAndIndex(blockHash: "0x0", index: 1234, subnetwork: subnetwork, handler: { (result, error) in
            XCTAssertNil(error)
            XCTAssertNotNil(result)
            expectation.fulfill()
        })
        
        waitForExpectations(timeout: 4, handler: nil)
    }

    func testetTransactionByBlockNumberAndIndex() {
        
        // Create an expectation
        let expectation = self.expectation(description: "getTransactionByBlockNumberAndIndex")
        
        try? PocketAion.eth.getTransactionByBlockNumberAndIndex(blockTag: .init(str: "1234"), index: 1234, subnetwork: subnetwork, handler: { (result, error) in
            XCTAssertNil(error)
            XCTAssertNotNil(result)
            expectation.fulfill()
        })
        
        waitForExpectations(timeout: 4, handler: nil)
    }

    func testGetTransactionReceipt() {
        
        // Create an expectation
        let expectation = self.expectation(description: "getTransactionReceipt")
        
        try? PocketAion.eth.getTransactionReceipt(txHash: "0x0", subnetwork: subnetwork, handler: { (result, error) in
            XCTAssertNil(error)
            XCTAssertNotNil(result)
            expectation.fulfill()
        })
        
        waitForExpectations(timeout: 4, handler: nil)

    }
    
    func testGetUncleByBlockHashAndIndex() {
        // Create an expectation
        let expectation = self.expectation(description: "getUncleByBlockHashAndIndex")
        
        try? PocketAion.eth.getUncleByBlockHashAndIndex(blockHash: "0x0", index: 1234, subnetwork: subnetwork, handler: { (result, error) in
            XCTAssertNil(error)
            XCTAssertNotNil(result)
            expectation.fulfill()
        })
        
        waitForExpectations(timeout: 4, handler: nil)
    }

    func testGetUncleByBlockNumberAndIndex() {
        
        // Create an expectation
        let expectation = self.expectation(description: "getUncleByBlockNumberAndIndex")
        
        try? PocketAion.eth.getUncleByBlockNumberAndIndex(blockTag: .init(str: "1234"), index: 1234, subnetwork: subnetwork, handler: { (result, error) in
            XCTAssertNil(error)
            XCTAssertNotNil(result)
            expectation.fulfill()
        })
        
        waitForExpectations(timeout: 4, handler: nil)
    }
    
    func testGetLogsByBlockHash() {
        // Create an expectation
        let expectation = self.expectation(description: "getLogs")
        
        try? PocketAion.eth.getLogs(fromBlock: nil, toBlock: nil, address: nil, topics: nil, blockhash: "0x0", subnetwork: subnetwork, handler: { (result, error) in
            XCTAssertNil(error)
            XCTAssertNotNil(result)
            expectation.fulfill()
        })
        
        waitForExpectations(timeout: 4, handler: nil)
    }
    
    func testGetLogsByBlockNumberTag() {
        // Create an expectation
        let expectation = self.expectation(description: "getLogs")
        
        try? PocketAion.eth.getLogs(fromBlock: BlockTag.init(str: "1234"), toBlock: BlockTag.init(str: "2000"), address: nil, topics: nil, blockhash: nil, subnetwork: subnetwork, handler: { (result, error) in
            XCTAssertNil(error)
            XCTAssertNotNil(result)
            expectation.fulfill()
        })
        
        waitForExpectations(timeout: 4, handler: nil)
    }

    func testGetWork() {
        // Create an expectation
        let expectation = self.expectation(description: "getWork")
        
        try? PocketAion.eth.getWork(subnetwork: subnetwork, handler: { (result, error) in
            XCTAssertNil(error)
            XCTAssertNotNil(result)
            expectation.fulfill()
        })
        
        waitForExpectations(timeout: 4, handler: nil)
    }
    // getProof
    // TODO: More scenarios for getProof
    func testGetProof() {
        guard let account = try? PocketAion.createWallet(subnetwork: subnetwork, data: nil) else {
            XCTFail("Failed to create account")
            return
        }
        
        // Create an expectation
        let expectation = self.expectation(description: "getProof")
        
        try? PocketAion.eth.getProof(address: account.address, storageKeys: [String](), blockTag: BlockTag.init(block: .LATEST), subnetwork: subnetwork, handler: { (result, error) in
            XCTAssertNil(error)
            XCTAssertNotNil(result)
            expectation.fulfill()
        })
        
        waitForExpectations(timeout: 4, handler: nil)
    }
    
    // MARK: NET RPC Tests
    func testVersion() {
        // Create an expectation
        let expectation = self.expectation(description: "version")
        
        try? PocketAion.net.version(subnetwork: subnetwork, handler: { (result, error) in
            XCTAssertNil(error)
            XCTAssertNotNil(result)
            expectation.fulfill()
        })
        
        waitForExpectations(timeout: 4, handler: nil)
    }
    func testListening() {
        // Create an expectation
        let expectation = self.expectation(description: "listening")
        
        try? PocketAion.net.listening(subnetwork: subnetwork, handler: { (result, error) in
            XCTAssertNil(error)
            XCTAssertNotNil(result)
            expectation.fulfill()
        })
        
        waitForExpectations(timeout: 4, handler: nil)
    }
    
    func testPeerCount() {
        // Create an expectation
        let expectation = self.expectation(description: "peerCount")
        
        try? PocketAion.net.peerCount(subnetwork: subnetwork, handler: { (result, error) in
            XCTAssertNil(error)
            XCTAssertNotNil(result)
            expectation.fulfill()
        })
        
        waitForExpectations(timeout: 4, handler: nil)
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
