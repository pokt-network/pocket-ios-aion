
var txObj = {
nonce: "%@",
to: "%@",
value: "%@",
data: "%@",
gas: "%@",
gasPrice: "%@",
type: 1
};

aionInstance.eth.accounts.signTransaction(txObj, "%@", function(error, result) {
window.transactionCreationCallback(error, result);
});
