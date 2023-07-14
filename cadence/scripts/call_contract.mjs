import * as fcl from "@onflow/fcl"
import * as types from "@onflow/types"
import { config } from "@onflow/fcl"

config({
    "accessNode.api": "https://rest-testnet.onflow.org"
  })
// Get latest block
const latestBlock = await fcl
.send([
  fcl.getBlock(true), // isSealed = true
])
.then(fcl.decode);

console.log(latestBlock)
// Get account from latest block height
const account = await fcl.account("0x6223108937e32f96");
//console.log(account)
// Get account at a specific block height
//await fcl.send([fcl.getAccount("0x6223108937e32f96"), fcl.atBlockHeight(110617606)]).then(fcl.decode)

// Or, create a custom authorization function
const authzFn = async (txAccount) => {
  return {
    ...txAccount,
    addr: "0x6223108937e32f96",
    keyId: 0,
    signingFunction: async(signable) => {
      return {
        addr: "0x6223108937e32f96",
        keyId: 0,
        signature
      }
    }
  }
}


// authorizer is the sender
await fcl.mutate({
  cadence: `
    transaction {
      prepare(acct: AuthAccount) {}
    }
  `,
  /*
  proposer: authzFn,
  payer: authzFn,
  authorizations: [authzFn],
  */
  authz: fcl.currentUser, // Optional. Will default to currentUser if not provided.
  limit: 50,
})