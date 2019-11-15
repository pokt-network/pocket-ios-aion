# NOTE:
This repository has been deprecated, please visit the [PocketSwift repository for the latest on Pocket iOS client development.](https://github.com/pokt-network/pocket-swift)

# Pocket IOS AION Plugin
AION IOS Plugin to connect to any AION compatible Pocket Node.
For more information about Pocket Node you can checkout the repo [here](https://github.com/pokt-network/pocket-node).


# Installation
Need to install the following pod in your Podfile:

`pod 'PocketAion', '~> 0.0.14'`

# About this plugin
A Pocket Network plugin will allow your application to send `Transaction` and `Query` objects to any given Pocket Node
that supports the AION network.

A `Transaction` refers to any calls that alter the state of the network: sending AION from one account to another, calling a smart contract, etc.

A `Query` refers to any calls that read data from the current state of the network: Getting an account balance, reading from a smart contract.

## Subnetwork considerations
A subnetwork in terms of a Pocket Node is any given parallel network for a decentralized system, for example
in the case of AION, besides Mainnet (subnetwork `256`), you also have access to the Mastery testnet (subnetwork `32`).
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
    
4- After we specified the URL, we need to set the `configuration` for Pocket in the `Application` function:
`
 Pocket.shared.setConfiguration(config: self)
`

## Creating and Importing a Wallet
Follow the following example to create an AION Wallet:

```
let wallet = try PocketAion.createWallet(subnetwork: subnetwork, data: nil)
```

And to import, you need to define:

1- Public Key

2- Private Key

3- Subnetwork

4- Data

```
let privateKey = "0x";
let address = "0x";
let subnetwork = "32";

var importedWallet = try PocketAion.importWallet(privateKey: privateKey, subnetwork: subnetwork, address: address, data: nil)
```

## Sending a transaction
The requirements to send a transaction which needs to be defined is:

1- Subnetwork: 256 (Main Network), 32 (Mastery Testnet).

2- Nonce: The wallet transaction count.

3- Wallet: Either by creating a new Wallet or importing one.

4- To: The address we wanna send the funds to.

5- Value: The amount of AION we want to send.

6- Data(optional): The hex encoded data of the transaction(if sending to a Smart Contract) or raw data being sent to a wallet.

7- NRG (Energy): The total computational steps we’re willing to execute on this transaction.

8- NRG Price (Energy Price)

To send a transaction, use the `sendTransaction` function in the `eth` namespace, like the example
below:

```

try? PocketAion.eth.sendTransaction(wallet: account, nonce: BigInt(1), to: "0x0", data: "", value: BigInt.init(20000000000), gasPrice: BigInt(10000000000), gas: BigInt(21000)) { (result, error) in
  // Result is the transaction hash
}

```

## Querying Data
Currently there are 2 supported namespaces in PocketAION: `net` and `eth` that contains prebuild `RPC_Methods` to call when executing each namespace.
In the examples below, you will see how we get the balance of a wallet using both namespaces.

```
try? PocketAion.eth.getBalance(address: "0x0...", subnetwork: "32", blockTag: BlockTag.init(block: .LATEST), handler: { (result, error) in
    // result is returned as a BigInt, also can be converted using the .toString() function
    // error if any contains a description of the error, returned by the Pocket Node
})
```

## Interacting with a smart contract
Before we begin interacting with a smart contract. We will need to `initialize` an instance of the `AionContract class`, we need to specify 4 params:

1- A PocketAion instance

2- The ABI of the Smart Contract

3- Contract Address

4- Subnetwork

### Initializing the AionContract instance
Here's an example of how to initialize your `AionContract`:

```
let pocketAion = PocketAion.init()
let contractAddress = "0x0..."
guard let contractABI = JSON.init(parseJSON: "[...]").array else {
    // if there was an error parsing the JSON array
    throw PocketPluginError.Aion.executionError("Failed to retrieve JSON ABI")
    return nil
}
// Finally initialize your AionContract
let aionContract = try AionContract.init(pocketAion: pocketAion, abiDefinition: contractABI, contractAddress: contractAddress, subnetwork: "32")

```

### Writing to a Smart Contract
Before we write to a contract, we need to define:

1- Function name

2- Function parameters

3- Nonce

4- NRG(Energy)

5- NRG Price (Energy Price)

6- Value

After we meet the params, we can now call the `executeFunction`:

```
let wallet = "0x0"
let funcParams = [Any]() 
functParams.append(BigInt.init(1)) // For this smart contract we are sending 1 
let nrg = BigInt.init(50000)
let nrgPrice = BigInt.init(10000000000)
let nonce = BigInt.init(0)
let value = BigInt.init(0)

try? aionContract.executeFunction(functionName: "addToState", wallet: wallet, functionParams: funcParams, nonce: nonce, nrg: nrg, nrgPrice: nrgPrice, value: value, handler: { (result, error) in
    // The result will contain the transaction hash
    // The error, if any, will contain the error sent from the Pocket Node
})
```

### Calling(query) an AionContract function
There are 2 main distinctions when calling a smart contract function: whether or not calling it alters
the state of the smart contract. This is indicated in the `constant` attribute of the JSON.

To read a smart contract you will need to use the `executeConstantFunction` call with the following parameters, see the example below:

1- Function name

2- Function parameters

3- From address(optional)

4- NRG (Energy, optional)

5- NRG Price (Energy Price, optional)

6- Value (optional)

```
try? contract.executeConstantFunction(functionName: "multiply", fromAdress: nil, functionParams: [any](), nrg: nil, nrgPrice: nil, value: nil, handler: { (result, error) in
    // Result will be a hex string representing the number 20: 0x14
    // Error, if any, will be the error returned by the Pocket Node
})
```

# References
Refer to the AION JSON RPC documentation [here](https://github.com/aionnetwork/aion/wiki/JSON-RPC-API-Docs) for more information on the available RPC methods you can call from your application.
