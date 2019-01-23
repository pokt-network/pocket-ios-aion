//
//  pocket_aionTests.swift
//  pocket-aionTests
//
//  Created by Pabel Nunez Landestoy on 12/7/18.
//  Copyright © 2018 Pocket Network. All rights reserved.
//

import XCTest
import JavaScriptCore
import BigInt
import SwiftyJSON
@testable import Pocket
@testable import pocket_aion

class pocket_aionTests: XCTestCase, Configuration {
    public var nodeURL: URL {
        get {
            return URL(string: "https://aion.pokt.network")!
        }
    }
    
    public enum subnetwork: Int {
        case mastery = 32
        case prod = 256
        
        func toString() -> String {
            switch self {
            case .mastery:
                return "32"
            case .prod:
                return "256"
            }
        }
    }
    
    
    public enum SmartContract: Int {
        case simple = 1
        case types = 2
        
        func jsonFileStr() throws -> String {
            switch self {
                case .simple:
                    return try PocketAion.getFileForResource(name: "simpleContract", ext: "json")
                case .types:
                    return try PocketAion.getFileForResource(name: "typeContract", ext: "json")
            }
        }
    }
    
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
        let wallet = try? PocketAion.createWallet(subnetwork: subnetwork.mastery.toString(), data: nil)
        // Check wallet validity
        testWalletValidity(wallet: wallet!)
    }
    
    // Tests for importWallet()
    func testImportWallet() {
        let walletToImport = try? PocketAion.createWallet(subnetwork: subnetwork.mastery.toString(), data: nil)
        let importedWallet = try? PocketAion.importWallet(privateKey: walletToImport?.privateKey ?? "", subnetwork: walletToImport?.subnetwork ?? subnetwork.mastery.toString(), address: walletToImport?.address, data: walletToImport?.data)
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
        let receiverAccount = try? PocketAion.createWallet(subnetwork: subnetwork.mastery.toString(), data: nil)
        
        // Transaction params
        let txParams = ["nonce": "1", "to": receiverAccount?.address ?? "", "data": "", "value": "0x989680", "nrgPrice": "0x989680", "nrg": "0x989680"]
        
        // Create account
        let account = try? PocketAion.createWallet(subnetwork: subnetwork.mastery.toString(), data: nil)
        // Transaction
        let signedTx = try? PocketAion.createTransaction(wallet: account!, params: txParams)
        
        // Verify signed transaction data
        XCTAssertNotNil(signedTx)
        XCTAssertNotNil(signedTx?.serializedTransaction)
        XCTAssertEqual("AION", signedTx?.network)
        XCTAssertEqual(subnetwork.mastery.toString(), signedTx?.subnetwork)
    }
    
    func testCreateTransactionTOError() {
        let wallet = try? PocketAion.createWallet(subnetwork: subnetwork.mastery.toString(), data: nil)
        
        var params = [AnyHashable : Any]()
        params["to"] = nil
        
        XCTAssertThrowsError(try PocketAion.createTransaction(wallet: wallet!, params: params))
    }
    
    // Tests for createQuery()
    func testCreateQuerySuccess() {
        let query = try? PocketAion.createQuery(subnetwork: subnetwork.mastery.toString(), params: ["rpcMethod": "eth_getTransactionCount", "rpcParams": ["0x0", "latest"]], decoder: nil)
        XCTAssertNotNil(query)
        XCTAssertNotNil(query?.data)
        XCTAssertEqual(query?.network, "AION")
        XCTAssertEqual(query?.subnetwork, subnetwork.mastery.toString())
        XCTAssertNotNil(query?.decoder)
    }
    
    func testCreateQueryRPCError() {
        XCTAssertThrowsError(try PocketAion.createQuery(subnetwork: subnetwork.mastery.toString(), params: ["failedKey": "failedValue"], decoder: nil))
    }
    
    // MARK: ETH RPC Tests
    func testGetBalanceSuccess() {
        guard let account = try? PocketAion.createWallet(subnetwork: subnetwork.mastery.toString(), data: nil) else {
            XCTFail("Failed to create account")
            return
        }
        
        // Create an expectation
        let expectation = self.expectation(description: "getBalance")
        
        try? PocketAion.eth.getBalance(address: account.address, subnetwork: subnetwork.mastery.toString(), blockTag: BlockTag.init(block: .LATEST), handler: { (result, error) in
            // Returns a BigInt, also can be converted toString()
            XCTAssertNil(error)
            XCTAssertNotNil(result)
            expectation.fulfill()
        })

        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testGetTransactionCount() {
        guard let account = try? PocketAion.createWallet(subnetwork: subnetwork.mastery.toString(), data: nil) else {
            XCTFail("Failed to create account")
            return
        }
        
        // Create an expectation
        let expectation = self.expectation(description: "getTransactionCount")
        
        try? PocketAion.eth.getTransactionCount(address: account.address, subnetwork: subnetwork.mastery.toString(), blockTag: BlockTag.init(block: .LATEST), handler: { (result, error) in
            XCTAssertNil(error)
            XCTAssertNotNil(result)
            expectation.fulfill()
        })
        
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testGetStorageAt() {

        // Create an expectation
        let expectation = self.expectation(description: "getStorageAt")
        
        try? PocketAion.eth.getStorageAt(address: "0xa061d41a9de8b2f317073cc331e616276c7fc37a80b0e05a7d0774c9cf956107", subnetwork: subnetwork.mastery.toString(), position: BigInt(0), blockTag: BlockTag.init(block: .LATEST), handler: { (results, error) in
            XCTAssertNil(error)
            XCTAssertNotNil(results)
            expectation.fulfill()
        })
        
        waitForExpectations(timeout: 4, handler: nil)
    }
    
    func testGetBlockTransactionCountByHash() {
        
        // Create an expectation
        let expectation = self.expectation(description: "getBlockTransactionCountByHash")
        
        try? PocketAion.eth.getBlockTransactionCountByHash(blockHash: "0xa9316ee7207cf2ac1fd886673d5c14835a86cda97eae8f0d382b95678932c8d0", subnetwork: subnetwork.mastery.toString(), handler: { (result, error) in
            XCTAssertNil(error)
            XCTAssertNotNil(result)
            expectation.fulfill()
        })

        waitForExpectations(timeout: 4, handler: nil)
    }
    
    func testGetBlockTransactionCountByNumber() {
        // Create an expectation
        let expectation = self.expectation(description: "getBlockTransactionCountByNumber")
        
        try? PocketAion.eth.getBlockTransactionCountByNumber(blockTag: BlockTag.init(str: "1323288"), subnetwork: subnetwork.mastery.toString(), handler: { (result, error) in
            XCTAssertNil(error)
            XCTAssertNotNil(result)
            expectation.fulfill()
        })
        
        waitForExpectations(timeout: 4, handler: nil)
    }

    func testGetCode() {
        
        // Create an expectation
        let expectation = self.expectation(description: "getCode")
        
        try? PocketAion.eth.getCode(address: "0xA0707404B9BE7a5F630fCed3763d28FA5C988964fDC25Aa621161657a7Bf4b89", subnetwork: subnetwork.mastery.toString(), blockTag: BlockTag.init(block: .LATEST), handler: { (result, error) in
            XCTAssertNil(error)
            XCTAssertNotNil(result)
            expectation.fulfill()
        })

        waitForExpectations(timeout: 4, handler: nil)
    }

    func testCall() {

        // Create an expectation
        let expectation = self.expectation(description: "call")
        
        try? PocketAion.eth.call(from: nil, to: "0xA0707404B9BE7a5F630fCed3763d28FA5C988964fDC25Aa621161657a7Bf4b89", nrg: BigInt.init(50000), nrgPrice: BigInt.init(20000000000), value: BigInt.init(20000000000), data: "0xbbaa08200000000000000000000000000000014c00000000000000000000000000000154", blockTag: BlockTag.init(block: .LATEST), subnetwork: subnetwork.mastery.toString(), handler: { (result, error) in
            XCTAssertNil(error)
            XCTAssertNotNil(result)
            expectation.fulfill()
        })

        waitForExpectations(timeout: 4, handler: nil)
    }
    
    func testSendTransaction(){
        guard let account = try? PocketAion.importWallet(privateKey: "0x2b5d6fd899ccc148b5f85b4ea20961678c04d70055b09dac7857ea430757e6badb4cfe129e670e2fef1b632ed0eab9572954feebbea9cb32134b284763acd34e", subnetwork: subnetwork.mastery.toString(), address: "0xa05b88ac239f20ba0a4d2f0edac8c44293e9b36fa937fb55bf7a1cd61a60f036", data: nil) else{
            XCTFail("Failed to create account")
            return
        }
        
        // Create an expectation
        let expectation = self.expectation(description: "getTransactionCountTest")
        let expectation2 = self.expectation(description: "sendTransaction")
        
        try? PocketAion.eth.getTransactionCount(address: account.address, subnetwork: account.subnetwork, blockTag: BlockTag.init(block: BlockTag.DefaultBlock.LATEST), handler: { (result, error) in
            
            XCTAssertNil(error)
            XCTAssertNotNil(result)
            expectation.fulfill()
            
            try? PocketAion.eth.sendTransaction(wallet: account, nonce: result!, to: "0xa07743f4170ded07da3ccd2ad926f9e684a5f61e90d018a3c5d8ea60a8b3406a", data: "", value: BigInt.init(20000000000), nrgPrice: BigInt.init(20000000000), nrg: BigInt.init(50000)) { (result, error) in
                XCTAssertNil(error)
                XCTAssertNotNil(result)
                expectation2.fulfill()
            }
            
        })
        
        waitForExpectations(timeout: 20, handler: nil)

    }

    func testGetBlockByHash() {
        
        // Create an expectation
        let expectation = self.expectation(description: "getBlockByHash")
        
        try? PocketAion.eth.getBlockByHash(blockHash: "0xa9316ee7207cf2ac1fd886673d5c14835a86cda97eae8f0d382b95678932c8d0", fullTx: false, subnetwork: subnetwork.mastery.toString(), handler: { (result, error) in
            XCTAssertNil(error)
            XCTAssertNotNil(result)
            expectation.fulfill()
        })

        waitForExpectations(timeout: 4, handler: nil)
    }
    
    func testGetBlockByNumber() {
        
        // Create an expectation
        let expectation = self.expectation(description: "getBlockByNumber")
        
        try? PocketAion.eth.getBlockByNumber(blockTag: BlockTag.init(block: .LATEST), fullTx: true, subnetwork: subnetwork.mastery.toString(), handler: { (result, error) in
            XCTAssertNil(error)
            XCTAssertNotNil(result)
            expectation.fulfill()
        })
        
        waitForExpectations(timeout: 4, handler: nil)
    }

    func testGetTransactionByHash() {
        
        // Create an expectation
        let expectation = self.expectation(description: "getTransactionByHash")
        
        try? PocketAion.eth.getTransactionByHash(txHash: "0x123075c535309a3b0dbbe5c97a7a5298ec7f1bd3ae1b684ec529df3ce16cab2e", subnetwork: subnetwork.mastery.toString(), handler: { (result, error) in
            XCTAssertNil(error)
            XCTAssertNotNil(result)
            expectation.fulfill()
        })
        
        waitForExpectations(timeout: 4, handler: nil)
    }

    func testGetTransactionByBlockHashAndIndex() {
        
        // Create an expectation
        let expectation = self.expectation(description: "getTransactionByBlockHashAndIndex")
        
        try? PocketAion.eth.getTransactionByBlockHashAndIndex(blockHash: "0x20b43393f0e0d2de098f74ed97cc7fdb06a6857d391ead0fd8756b9c18bb98e6", index: BigInt(0), subnetwork: subnetwork.mastery.toString(), handler: { (result, error) in
            XCTAssertNil(error)
            XCTAssertNotNil(result)
            expectation.fulfill()
        })
        
        waitForExpectations(timeout: 4, handler: nil)
    }

    func testGetTransactionByBlockNumberAndIndex() {
        
        // Create an expectation
        let expectation = self.expectation(description: "getTransactionByBlockNumberAndIndex")
        
        try? PocketAion.eth.getTransactionByBlockNumberAndIndex(blockTag: .init(str: "1329667"), index: 0, subnetwork: subnetwork.mastery.toString(), handler: { (result, error) in
            XCTAssertNil(error)
            XCTAssertNotNil(result)
            expectation.fulfill()
        })
        
        waitForExpectations(timeout: 4, handler: nil)
    }

    func testGetTransactionReceipt() {
        
        // Create an expectation
        let expectation = self.expectation(description: "getTransactionReceipt")
        
        try? PocketAion.eth.getTransactionReceipt(txHash: "0xddb6499420a12ce78cd43874565507aa32b101bd7ae0ce3aae3175960cefac40", subnetwork: subnetwork.mastery.toString(), handler: { (result, error) in
            XCTAssertNil(error)
            XCTAssertNotNil(result)
            expectation.fulfill()
        })
        
        waitForExpectations(timeout: 4, handler: nil)

    }
    
    func testGetLogsByBlockHash() {
        // Create an expectation
        let expectation = self.expectation(description: "getLogs")
        
        try? PocketAion.eth.getLogs(fromBlock: nil, toBlock: nil, address: nil, topics: nil, blockhash: "0xc89d0feda0a748e701b03b90e7e04f24b3c499439bf0d0dc630e2d590388f4a8", subnetwork: subnetwork.mastery.toString(), handler: { (result, error) in
            XCTAssertNil(error)
            XCTAssertNotNil(result)
            expectation.fulfill()
        })
        
        waitForExpectations(timeout: 30, handler: nil)
    }
    
    func testGetLogsByBlockNumberTag() {
        // Create an expectation
        let expectation = self.expectation(description: "getLogs")
        
        try? PocketAion.eth.getLogs(fromBlock: nil, toBlock: BlockTag.init(block: .LATEST), address: nil, topics: nil, blockhash: nil, subnetwork: subnetwork.mastery.toString(), handler: { (result, error) in
            XCTAssertNil(error)
            XCTAssertNotNil(result)
            expectation.fulfill()
        })
        
        waitForExpectations(timeout: 30, handler: nil)
    }
    
    // MARK: NET RPC Tests
    func testVersion() {
        // Create an expectation
        let expectation = self.expectation(description: "version")
        
        try? PocketAion.net.version(subnetwork: subnetwork.mastery.toString(), handler: { (result, error) in
            XCTAssertNil(error)
            XCTAssertNotNil(result)
            expectation.fulfill()
        })
        
        waitForExpectations(timeout: 4, handler: nil)
    }
    func testListening() {
        // Create an expectation
        let expectation = self.expectation(description: "listening")
        
        try? PocketAion.net.listening(subnetwork: subnetwork.mastery.toString(), handler: { (result, error) in
            XCTAssertNil(error)
            XCTAssertNotNil(result)
            expectation.fulfill()
        })
        
        waitForExpectations(timeout: 4, handler: nil)
    }
    
    func testPeerCount() {
        // Create an expectation
        let expectation = self.expectation(description: "peerCount")
        
        try? PocketAion.net.peerCount(subnetwork: subnetwork.mastery.toString(), handler: { (result, error) in
            XCTAssertNil(error)
            XCTAssertNotNil(result)
            expectation.fulfill()
        })
        
        waitForExpectations(timeout: 4, handler: nil)
    }
    
    // Aion Contract tests
    
    func testSimpleConstantFunctionCall() {
        // Get the contract instance
        guard let contract = try? getAionContractInstance(abiInterfaceJSON: SmartContract.simple, contractAdress: "0xA0707404B9BE7a5F630fCed3763d28FA5C988964fDC25Aa621161657a7Bf4b89") else {
            XCTFail("Failed to get aion contract instance")
            return
        }
        
        // Create an expectation
        let expectation = self.expectation(description: "simpleConstantFunctionCall")
        
        // Prepare parameters
        var functionParams = [Any]()
        functionParams.append(BigInt.init(2))
        functionParams.append(BigInt.init(10))
        
        try? contract!.executeConstantFunction(functionName: "multiply", fromAdress: nil, functionParams: functionParams, nrg: BigInt.init(50000), nrgPrice: BigInt.init(20000000000), value: nil, handler: { (result, error) in
            // Since we know from JSON ABI that the return value is a uint128 we can check if it's type BigInteger
            // Result should be 2 * 10 = 20
            XCTAssertNil(error)
            XCTAssertNotNil(result)
            let hexResult = result?.first as? String
            let hexResultBigInt = BigInt.init(HexStringUtil.removeLeadingZeroX(hex: hexResult ?? "0") ?? "0", radix: 16)
            XCTAssertEqual(hexResultBigInt, BigInt("20"))
            
            expectation.fulfill()
        })
        
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testTypeEncodingAndDecoding() {
        
        // Get the contract instance
        guard let contract = try? getAionContractInstance(abiInterfaceJSON: SmartContract.simple, contractAdress: "0xA0707404B9BE7a5F630fCed3763d28FA5C988964fDC25Aa621161657a7Bf4b89") else {
            XCTFail("Failed to get aion conract instance")
            return
        }
        
        // Create an expectation
        let expectation = self.expectation(description: "typeEncodingAndDecoding")

        // Prepare parameters
        var functionParams = [String]()
        functionParams.append(BigInt.init(10).toString(radix: 16))
        functionParams.append("true")
        functionParams.append("Hello World!")
        
        try? contract!.executeConstantFunction(functionName: "echo", fromAdress: nil, functionParams: functionParams, nrg: BigInt.init(50000), nrgPrice: BigInt.init(20000000000), value: nil, handler: { (result, error) in
            // Since we know from JSON ABI that the return value is an array, we can decode it
            XCTAssertNil(error)
            XCTAssertNotNil(result)
            expectation.fulfill()
        })
        
        waitForExpectations(timeout: 5, handler: nil)
    }

    // MARK: Tools
    func getAionContractInstance(abiInterfaceJSON: SmartContract, contractAdress: String) throws -> AionContract?{
        var abiInterface = ""
        let pocketAion = PocketAion.init()
        
        switch abiInterfaceJSON {
            case .simple:
                abiInterface = try SmartContract.simple.jsonFileStr()
            case .types:
                abiInterface = try SmartContract.types.jsonFileStr()
        }
        
        guard let jsonArray = JSON.init(parseJSON: abiInterface).array else {
            XCTFail("Failed to retrieve abi interface json array")
            return nil
        }
        
        return try AionContract.init(pocketAion: pocketAion, abiDefinition: jsonArray, contractAddress: contractAdress, subnetwork: subnetwork.mastery.toString())
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
