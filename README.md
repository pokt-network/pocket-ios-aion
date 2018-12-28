# Pocket IOS AION Plugin
AION IOS Plugin to connect to any AION compatible Pocket Node. 
For more information about Pocket Node you can checkout the repo [here](https://github.com/pokt-network/pocket-node).

# Installation
Need to install the following pod in your Podfile:

`pod 'PocketAion', '~> 0.0.1'`

# About this plugin
A Pocket Network plugin will allow your application to send `Transaction` and `Query` objects to any given Pocket Node
that supports the AION network.

A `Transaction` refers to any calls that alter the state of the network: sending AION from one account to another, calling a smart contract, etc.

A `Query` refers to any calls that read data from the current state of the network: Getting an account balance, reading from a smart contract.

## Subnetwork considerations
A subnetwork in terms of a Pocket Node is any given parallel network for a decentralized system, for example
in the case of AION, besides Mainnet (subnetwork `main`), you also have access to the Mastery testnet (subnetwork `mastery`). 
In the case of connecting to a custom network, make sure the Pocket Node you are connecting to supports the given subnetwork.

This is useful to allow users to hop between networks, or for establishing differences between your application's 
test environment and production environments.

# Using a Pocket IOS Plugin
Just import the `PocketAion` class and call into any of the functions described below. In addition to that you can use
the functions below to send the created `Transaction` and `Query` objects to your configured Pocket Node, either synchronously or asynchronously.

## The Configuration object
The constructor for any given `PocketAion` instance requires a class implementing the `Configuration` interface. 
Let's take a look at the example below:

1- In your `appDelegate` import `Pocket` and `PocketAion`
2- Add `Configuration` protocol to the class:
    `class AppDelegate: UIResponder, UIApplicationDelegate, Configuration, {`

3- Implement `nodeURL` with the node url:
   `var nodeURL: URL {
        get {
            return URL.init(string: "https://aion.pokt.network")!
        }
    }`

## Creating and Importing a Wallet
Follow the following example to create an AION Wallet:

`public static func createWallet(subnetwork: String, data: [AnyHashable : Any]?) throws -> Wallet`

```
var wallet = try PocketAion.createWallet(subnetwork: subnetwork, data: nil)
```

And to import:

`public static func importWallet(subnetwork: String, privateKey: String, address: String?, data: [AnyHashable : Any]?) throws -> Wallet`

```
let privateKey = "0x";
let address = "0x";

var importedWallet = try PocketAion.importWallet(privateKey: privateKey, subnetwork: subnetwork, address: address, data: nil)
```

## Creating and sending a Transaction
Follow the example below to create a `Transaction` object to write to the given AION network with the parameters below and `subnetwork`. 
Throws `transactionCreationError` in case of errors.

```
// First import the sender's wallet
let privateKey = "0x";
let address = "0x";

var importedWallet = try PocketAion.importWallet(privateKey: privateKey, subnetwork: subnetwork, address: address, data: nil)

// Build your transaction parameters
var txParams = [Anyhashable: Any]()

txParams["nonce"] = "1"
txParams["to"] = importedWallet?.address ?? ""
txParams["value"] = "0x989680"

// You can pass in correctly encoded data argument to your transaction in the case of calling a smart contract.
txParams["data"] = ""
txParams["gasPrice"] = "0x989680"
txParams["gas"] = "0x989680"

// Create and sign your Transaction object
let signedTx = try PocketAion.createTransaction(wallet: importedWallet!, params: txParams)
```

To send your newly created `Transaction` to the node use the `sendTransaction` method:

```
PocketAion.shared.sendTransaction(transaction: signedTx) { (transactionResponse, error) in
  // Check for errors and the response hash
}
```

## Creating and sending a Query
Follow the example below to create a `Transaction` object to write to the given AION network with the parameters below and `subnetwork`. 
Throws `queryCreationError` in case of errors.

```
let network = "mastery"
var queryParams = ["rpcMethod": "eth_getTransactionCount", "rpcParams": ["0x0", "latest"]]

var query = try PocketAion.createQuery(subnetwork: network, params: queryParams, decoder: nil)
```

To send your `Query` to the node use the `executeQuery` method:

```
Pocket.shared.executeQuery(query: query) { (queryResponse, error) in
  // Check for errors and the response hash
}
```

# References
Refer to the AION JSON RPC documentation [here](https://github.com/aionnetwork/aion/wiki/JSON-RPC-API-Docs) for more information on the available RPC methods you can call from your application.
