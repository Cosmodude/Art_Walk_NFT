import * as fcl from "@onflow/fcl"
import {config} from "@onflow/fcl"
import { useState, useEffect } from "react"

config({
    "accessNode.api": "https://rest-testnet.onflow.org",
    "discovery.wallet": "https://fcl-discovery.onflow.org/testnet/authn",
    "discovery.wallet.method": "POP/RPC", // Optional. Available methods are "IFRAME/RPC", "POP/RPC", "TAB/RPC" or "HTTP/POST", defaults to "IFRAME/RPC".
    "app.detail.title": "ArtWalk"
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

export default function Home() {

  const [user, setUser] = useState({loggedIn: null})
  const [name, setName] = useState('')

  useEffect(() => fcl.currentUser.subscribe(setUser), [])

  const sendQuery = async () => {
    const profile = await fcl.query({
      cadence: `
        import Profile from 0xProfile

        pub fun main(address: Address): Profile.ReadOnly? {
          return Profile.read(address)
        }
      `,
      args: (arg, t) => [arg(user.addr, t.Address)]
    })

    setName(profile?.name ?? 'No Profile')
  }

  // NEW
  const initAccount = async () => {
    const transactionId = await fcl.mutate({
      cadence: `
        import Profile from 0xProfile

        transaction {
          prepare(account: AuthAccount) {
            // Only initialize the account if it hasn't already been initialized
            if (!Profile.check(account.address)) {
              // This creates and stores the profile in the user's account
              account.save(<- Profile.new(), to: Profile.privatePath)

              // This creates the public capability that lets applications read the profile's info
              account.link<&Profile.Base{Profile.Public}>(Profile.publicPath, target: Profile.privatePath)
            }
          }
        }
      `,
      payer: fcl.authz,
      proposer: fcl.authz,
      authorizations: [fcl.authz],
      limit: 50
    })

    const transaction = await fcl.tx(transactionId).onceSealed()
    console.log(transaction)
  }

  const AuthedState = () => {
    return (
      <div>
        <div>Address: {user?.addr ?? "No Address"}</div>
        <div>Profile Name: {name ?? "--"}</div>
        <button onClick={sendQuery}>Send Query</button>
        <button onClick={initAccount}>Init Account</button> {/* NEW */}
        <button onClick={fcl.unauthenticate}>Log Out</button>
      </div>
    )
  }

  const UnauthenticatedState = () => {
    return (
      <div>
        <button onClick={fcl.logIn}>Log In</button>
        <button onClick={fcl.signUp}>Sign Up</button>
      </div>
    )
  }

  return (
    <div>
      <h1>Flow App</h1>
      {user.loggedIn
        ? <AuthedState />
        : <UnauthenticatedState />
      }
    </div>
  )
}