export const MINT_ARTWALK = `
  import ArtWalk from 0xArtWalk
  import FUSD from 0xFUSD
  import FungibleToken from 0xFungibleToken


  transaction(templateID: UInt32, amount: UFix64) {
    let receiverReference: &ArtWalk.Collection{ArtWalk.Receiver}
    let sentVault: @FungibleToken.Vault

    prepare(acct: AuthAccount) {
      self.receiverReference = acct.borrow<&ArtWalk.Collection>(from: ArtWalk.CollectionStoragePath) 
          ?? panic("Cannot borrow")
      let vaultRef = acct.borrow<&FUSD.Vault>(from: /storage/fusdVault) ?? panic("Could not borrow FUSD vault")
      self.sentVault <- vaultRef.withdraw(amount: amount)
    }

    execute {
      let newArtWalk <- ArtWalk.mintNFT(
        recipient: self.receiverReference,
        name: "My Walk",
        description: "Test Walk for the Flow hackathon,
        thumbnail: "",
        royalties: [MetadataViews.Royalty]
      )
      
    }
  }
`