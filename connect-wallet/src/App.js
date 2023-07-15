
import './App.css';
import * as fcl from "@onflow/fcl"
import {config} from "@onflow/fcl"
import { useState, useEffect } from "react"

config({
    "accessNode.api": "https://rest-testnet.onflow.org",
    "discovery.wallet": "https://fcl-discovery.onflow.org/testnet/authn",
    "discovery.wallet.method": "POP/RPC", // Optional. Available methods are "IFRAME/RPC", "POP/RPC", "TAB/RPC" or "HTTP/POST", defaults to "IFRAME/RPC".
    "discovery.authn.endpoint": "https://fcl-discovery.onflow.org/api/testnet/authn",
    "app.detail.title": "ArtWalk"
})

function App() {
  const [services, setServices] = useState([])
  useEffect(() => fcl.discovery.authn.subscribe(res => setServices(res.results)), [])

 
  return (
    <div>
    {services.map(service => <button key={service.provider.address} onClick={() => fcl.authenticate({ service })}>Login with {service.provider.name}</button>)}
  </div>
  );
}

export default App;
