// https://github.com/onflow/kitty-items/blob/master/cadence/contracts/KittyItems.cdc

import NonFungibleToken from "./NonFungibleToken.cdc"
import MetadataViews from "./MetadataViews.cdc"


pub contract ArtWalk: NonFungibleToken {

    // totalSupply
    // The total number of ArtWalks that have been minted
    //
    pub var totalSupply: UInt64

    // Events
    //
    pub event ContractInitialized()
    pub event Withdraw(id: UInt64, from: Address?)
    pub event Deposit(id: UInt64, to: Address?)
    pub event Minted(id: UInt64, kind: UInt8, difficulty: UInt8)
    pub event ImagesAddedForNewKind(kind: UInt8)

    // Named Paths
    //
    pub let CollectionStoragePath: StoragePath
    pub let CollectionPublicPath: PublicPath
    pub let MinterStoragePath: StoragePath

    pub enum Difficulty: UInt8 {
        pub case easy
        pub case normal
        pub case hard
        pub case expert
    }

    pub fun difficultyToString(_ difficulty: Difficulty): String {
        switch difficulty {
            case Difficulty.easy:
                return "Easy"
            case Difficulty.normal:
                return "Normal"
            case Difficulty.hard:
                return "Hard"
            case Difficulty.expert:
                return "Expert"
        }

        return ""
    }

    pub enum Kind: UInt8 {
        pub case city
        pub case park
        pub case forest
        pub case stadium
        pub case inside
    }

    pub fun kindToString(_ kind: Kind): String {
        switch kind {
            case Kind.city:
                return "City"
            case Kind.park:
                return "Park"
            case Kind.forest:
                return "Forest"
            case Kind.stadium:
                return "Stadium"
            case Kind.inside:
                return "Inside"
        }

        return ""
    }

    // Mapping from walk (kind, difficulty) -> IPFS image CID
    //
    access(self) var images: {Kind: {Difficulty: String}}

    // Mapping from difficulty -> price
    //
    access(self) var walkDifficultyPriceMap: {Difficulty: UFix64}

    // Return the initial sale price for an walk of this difficulty.
    //
    pub fun getWalkPrice(difficulty: Difficulty): UFix64 {
        return self.walkDifficultyPriceMap[difficulty]!
    }
    
    // An ArtWalk as an NFT
    //
    pub resource NFT: NonFungibleToken.INFT, MetadataViews.Resolver {
        pub let id: UInt64

        pub fun name(): String {
            return ArtWalk.difficultyToString(self.difficulty)
                .concat(" ")
                .concat(ArtWalk.kindToString(self.kind))
        }
        
        pub fun description(): String {
            return "A "
                .concat(ArtWalk.difficultyToString(self.difficulty).toLower())
                .concat(" ")
                .concat(ArtWalk.kindToString(self.kind).toLower())
                .concat(" with serial number ")
                .concat(self.id.toString())
        }

        pub fun imageCID(): String {
            return ArtWalk.images[self.kind]![self.difficulty]!
        }

        pub fun thumbnail(): MetadataViews.IPFSFile {
          return MetadataViews.IPFSFile(cid: self.imageCID(), path: "sm.png")
        }

        access(self) let royalties: [MetadataViews.Royalty]
        access(self) let metadata: {String: AnyStruct}

        // The walk kind (e.g. Forest)
        pub let kind: Kind

        // The walk difficulty (e.g. Normal)
        pub let difficulty: Difficulty

        init(
            id: UInt64,
            royalties: [MetadataViews.Royalty],
            metadata: {String: AnyStruct},
            kind: Kind, 
            difficulty: Difficulty,      
        ){
            self.id = id
            self.royalties = royalties
            self.metadata = metadata
            self.kind = kind
            self.difficulty = difficulty
        }

        pub fun getViews(): [Type] {
            return [
                Type<MetadataViews.Display>(),
                Type<MetadataViews.Royalties>(),
                Type<MetadataViews.Editions>(),
                Type<MetadataViews.ExternalURL>(),
                Type<MetadataViews.NFTCollectionData>(),
                Type<MetadataViews.NFTCollectionDisplay>(),
                Type<MetadataViews.Serial>(),
                Type<MetadataViews.Traits>()
            ]
        }

        pub fun resolveView(_ view: Type): AnyStruct? {
            switch view {
                case Type<MetadataViews.Display>():
                    return MetadataViews.Display(
                        name: self.name(),
                        description: self.description(),
                        thumbnail: self.thumbnail()
                    )
                case Type<MetadataViews.Editions>():
                    // There is no max number of NFTs that can be minted from this contract
                    // so the max edition field value is set to nil
                    let editionInfo = MetadataViews.Edition(name: "ArtWalk NFT Edition", number: self.id, max: nil)
                    let editionList: [MetadataViews.Edition] = [editionInfo]
                    return MetadataViews.Editions(
                        editionList
                    )
                case Type<MetadataViews.Serial>():
                    return MetadataViews.Serial(
                        self.id
                    )
                case Type<MetadataViews.Royalties>():
                    return MetadataViews.Royalties(
                        self.royalties
                    )
                case Type<MetadataViews.ExternalURL>():
                    return MetadataViews.ExternalURL("https://kitty-items.flow.com/".concat(self.id.toString()))
                case Type<MetadataViews.NFTCollectionData>():
                    return MetadataViews.NFTCollectionData(
                        storagePath: ArtWalk.CollectionStoragePath,
                        publicPath: ArtWalk.CollectionPublicPath,
                        providerPath: /private/ArtWalkCollection,
                        publicCollection: Type<&ArtWalk.Collection{ArtWalk.ArtWalkCollectionPublic}>(),
                        publicLinkedType: Type<&ArtWalk.Collection{ArtWalk.ArtWalkCollectionPublic,NonFungibleToken.CollectionPublic,NonFungibleToken.Receiver,MetadataViews.ResolverCollection}>(),
                        providerLinkedType: Type<&ArtWalk.Collection{ArtWalk.ArtWalkCollectionPublic,NonFungibleToken.CollectionPublic,NonFungibleToken.Provider,MetadataViews.ResolverCollection}>(),
                        createEmptyCollectionFunction: (fun (): @NonFungibleToken.Collection {
                            return <-ArtWalk.createEmptyCollection()
                        })
                    )
                case Type<MetadataViews.NFTCollectionDisplay>():
                    let media = MetadataViews.Media(
                        file: MetadataViews.HTTPFile(
                            url: "https://assets.website-files.com/5f6294c0c7a8cdd643b1c820/5f6294c0c7a8cda55cb1c936_Flow_Wordmark.svg"
                        ),
                        mediaType: "image/svg+xml"
                    )
                    return MetadataViews.NFTCollectionDisplay(
                        name: "The ArtWalk Collection",
                        description: "This collection is used as a part of ArtWalk Dapp to make physical activity funnier.",
                        externalURL: MetadataViews.ExternalURL("https://github.com/gylman/artwalk"),
                        squareImage: media,
                        bannerImage: media,
                        socials: {
                            "twitter": MetadataViews.ExternalURL("https://github.com/gylman/artwalk")
                        }
                    )
                case Type<MetadataViews.Traits>():
                    // exclude mintedTime and foo to show other uses of Traits
                    let excludedTraits = ["mintedTime","foo"]
                    let traitsView = MetadataViews.dictToTraits(dict: self.metadata, excludedNames: excludedTraits)

                    // mintedTime is a unix timestamp, we should mark it with a displayType so platforms know how to show it.
                    let mintedTimeTrait = MetadataViews.Trait(name: "mintedTime", value: self.metadata["mintedTime"]!, displayType: "Date", difficulty: nil)
                    traitsView.addTrait(mintedTimeTrait)

                    // foo is a trait with its own rarity
                    let fooTraitRarity = MetadataViews.Rarity(score: 10.0, max: 100.0, description: "Common")
                    let fooTrait = MetadataViews.Trait(name: "foo", value: self.metadata["foo"], displayType: nil, difficulty: fooTraitRarity)
                    traitsView.addTrait(fooTrait)
                    
                    return traitsView

            }
            return nil    
        }
    }

    // This is the interface that users can cast their ArtWalk Collection as
    // to allow others to deposit ArtWalks into their Collection. It also allows for reading
    // the details of ArtWalks in the Collection.
    pub resource interface ArtWalkCollectionPublic {
        pub fun deposit(token: @NonFungibleToken.NFT)
        pub fun getIDs(): [UInt64]
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT
        pub fun borrowArtWalk(id: UInt64): &ArtWalk.NFT? {
            // If the result isn't nil, the id of the returned reference
            // should be the same as the argument to the function
            post {
                (result == nil) || (result?.id == id):
                    "Cannot borrow ArtWalk reference: The ID of the returned reference is incorrect"
            }
        }
    }

    // Collection
    // A collection of ArtWalk NFTs owned by an account
    //
    pub resource Collection: ArtWalkCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, MetadataViews.ResolverCollection {
        // dictionary of NFT conforming tokens
        // NFT is a resource type with an `UInt64` ID field
        //
        pub var ownedNFTs: @{UInt64: NonFungibleToken.NFT}

        // initializer
        //
        init () {
            self.ownedNFTs <- {}
        }

        // withdraw 
        // removes an NFT from the collection and moves it to the caller
        pub fun withdraw(withdrawID: UInt64): @NonFungibleToken.NFT {
            let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")

            emit Withdraw(id: token.id, from: self.owner?.address)

            return <-token
        }

        // deposit 
        // takes a NFT and adds it to the collections dictionary
        // and adds the ID to the id array
        pub fun deposit(token: @NonFungibleToken.NFT) {
            let token <- token as! @ArtWalk.NFT

            let id: UInt64 = token.id

            // add the new token to the dictionary which removes the old one
            let oldToken <- self.ownedNFTs[id] <- token

            emit Deposit(id: id, to: self.owner?.address)

            destroy oldToken
        }

        // getIDs 
        // returns an array of the IDs that are in the collection
        pub fun getIDs(): [UInt64] {
            return self.ownedNFTs.keys
        }

        // borrowNFT 
        // gets a reference to an NFT in the collection
        // so that the caller can read its metadata and call its methods
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT {
            return (&self.ownedNFTs[id] as &NonFungibleToken.NFT?)!
        }

        // borrowArtWalks
        // Gets a reference to an NFT in the collection as an ArtWalk,
        // exposing all of its fields (including the typeID & difficultyID).
        // This is safe as there are no functions that can be called on the ArtWalk.
        //
        pub fun borrowArtWalk(id: UInt64): &ArtWalk.NFT? {
            if self.ownedNFTs[id] != nil {
                // Create an authorized reference to allow downcasting
                let ref = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
                return ref as! &ArtWalk.NFT
            } else {
                return nil
            }    
        }

        pub fun borrowViewResolver(id: UInt64): &AnyResource{MetadataViews.Resolver} {
            let nft = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
            let artWalk = nft as! &ArtWalk.NFT
            return artWalk as &AnyResource{MetadataViews.Resolver}
        }

        // destructor
        destroy() {
            destroy self.ownedNFTs
        }
    }

    // createEmptyCollection
    // public function that anyone can call to create a new empty collection
    //
    pub fun createEmptyCollection(): @NonFungibleToken.Collection {
        return <- create Collection()
    }

    // NFTMinter
    // Resource that an admin or something similar would own to be
    // able to mint new NFTs
    //
    pub resource NFTMinter {

        // mintNFT
        // Mints a new NFT with a new ID
        // and deposit it in the recipients collection using their collection reference
        //
        pub fun mintNFT(
            recipient: &{NonFungibleToken.CollectionPublic}, 
            kind: Kind, 
            difficulty: Difficulty,
            royalties: [MetadataViews.Royalty],
        ) {
            let metadata: {String: AnyStruct} = {}
            let currentBlock = getCurrentBlock()
            metadata["mintedBlock"] = currentBlock.height
            metadata["mintedTime"] = currentBlock.timestamp
            metadata["minter"] = recipient.owner!.address

            // this piece of metadata will be used to show embedding difficulty into a trait
            // metadata["foo"] = "bar"

            // create a new NFT
            var newNFT <- create ArtWalk.NFT(
                id: ArtWalk.totalSupply,
                royalties: royalties,
                metadata: metadata,
                kind: kind, 
                difficulty: difficulty
            )

            // deposit it in the recipient's account using their reference
            recipient.deposit(token: <-newNFT)

            emit Minted(
                id: ArtWalk.totalSupply,
                kind: kind.rawValue,
                difficulty: difficulty.rawValue,
            )

            ArtWalk.totalSupply = ArtWalk.totalSupply + 1 
        }

        // Update NFT images for new type
        pub fun addNewImagesForKind(from: AuthAccount, newImages: {Kind: {Difficulty: String}}) {
            let kindValue = ArtWalk.images.containsKey(newImages.keys[0]) 
            if(!kindValue) {
                ArtWalk.images.insert(key: newImages.keys[0], newImages.values[0])
                emit ImagesAddedForNewKind(
                    kind: newImages.keys[0].rawValue,
                )
            } else {
                panic("No Rugs... Can't update existing NFT images.")
            }
        }
    }

    // fetch
    // Get a reference to am ArtWalk from an account's Collection, if available.
    // If an account does not have an ArtWalk.Collection, panic.
    // If it has a collection but does not contain the walkID, return nil.
    // If it has a collection and that collection contains the walkID, return a reference to that.
    //
    pub fun fetch(_ from: Address, walkID: UInt64): &ArtWalk.NFT? {
        let collection = getAccount(from)
            .getCapability(ArtWalk.CollectionPublicPath)!
            .borrow<&ArtWalk.Collection{ArtWalk.ArtWalkCollectionPublic}>()
            ?? panic("Couldn't get collection")
        // We trust ArtWalk.Collection.borowArtWalk to get the correct walkID
        // (it checks it before returning it).
        return collection.borrowArtWalk(id: walkID)
    }

    // initializer
    //
    init() {
        // set difficulty price mapping
        self.walkDifficultyPriceMap = {
            Difficulty.expert: 125.0,
            Difficulty.hard: 25.0,
            Difficulty.normal: 5.0,
            Difficulty.easy: 1.0
        }

        self.images = {
            Kind.city: {
                Difficulty.easy: "bafybeibuqzhuoj6ychlckjn6cgfb5zfurggs2x7pvvzjtdcmvizu2fg6ga",
                Difficulty.normal: "bafybeihbminj62owneu3fjhtqm7ghs7q2rastna6srqtysqmjcsicmn7oa",
                Difficulty.hard: "bafybeiaoja3gyoot4f5yxs4b7tucgaoj3kutu7sxupacddxeibod5hkw7m",
                Difficulty.expert: "bafybeid73gt3qduwn2hhyy4wzhsvt6ahzmutiwosfd3f6t5el6yjqqxd3u"
            },
            Kind.forest: {
                Difficulty.easy: "bafybeibuqzhuoj6ychlckjn6cgfb5zfurggs2x7pvvzjtdcmvizu2fg6ga",
                Difficulty.normal: "bafybeihbminj62owneu3fjhtqm7ghs7q2rastna6srqtysqmjcsicmn7oa",
                Difficulty.hard: "bafybeiaoja3gyoot4f5yxs4b7tucgaoj3kutu7sxupacddxeibod5hkw7m",
                Difficulty.expert: "bafybeid73gt3qduwn2hhyy4wzhsvt6ahzmutiwosfd3f6t5el6yjqqxd3u"
            },
            Kind.park: {
                Difficulty.easy: "bafybeibuqzhuoj6ychlckjn6cgfb5zfurggs2x7pvvzjtdcmvizu2fg6ga",
                Difficulty.normal: "bafybeihbminj62owneu3fjhtqm7ghs7q2rastna6srqtysqmjcsicmn7oa",
                Difficulty.hard: "bafybeiaoja3gyoot4f5yxs4b7tucgaoj3kutu7sxupacddxeibod5hkw7m",
                Difficulty.expert: "bafybeid73gt3qduwn2hhyy4wzhsvt6ahzmutiwosfd3f6t5el6yjqqxd3u"
            },
            Kind.stadium: {
                Difficulty.easy: "bafybeibuqzhuoj6ychlckjn6cgfb5zfurggs2x7pvvzjtdcmvizu2fg6ga",
                Difficulty.normal: "bafybeihbminj62owneu3fjhtqm7ghs7q2rastna6srqtysqmjcsicmn7oa",
                Difficulty.hard: "bafybeiaoja3gyoot4f5yxs4b7tucgaoj3kutu7sxupacddxeibod5hkw7m",
                Difficulty.expert: "bafybeid73gt3qduwn2hhyy4wzhsvt6ahzmutiwosfd3f6t5el6yjqqxd3u"
            },
            Kind.inside: {
                Difficulty.easy: "bafybeibuqzhuoj6ychlckjn6cgfb5zfurggs2x7pvvzjtdcmvizu2fg6ga",
                Difficulty.normal: "bafybeihbminj62owneu3fjhtqm7ghs7q2rastna6srqtysqmjcsicmn7oa",
                Difficulty.hard: "bafybeiaoja3gyoot4f5yxs4b7tucgaoj3kutu7sxupacddxeibod5hkw7m",
                Difficulty.expert: "bafybeid73gt3qduwn2hhyy4wzhsvt6ahzmutiwosfd3f6t5el6yjqqxd3u"
            }
        }

        // Initialize the total supply
        self.totalSupply = 0

        // Set our named paths
        self.CollectionStoragePath = /storage/artWalkCollectionV14
        self.CollectionPublicPath = /public/artWalkCollectionV14
        self.MinterStoragePath = /storage/artWalkMinterV14

        // Create a Collection resource and save it to storage
        let collection <- create Collection()
        self.account.save(<-collection, to: self.CollectionStoragePath)

        // Create a public capability for the collection
        self.account.link<&ArtWalk.Collection{NonFungibleToken.CollectionPublic, ArtWalk.ArtWalkCollectionPublic, MetadataViews.ResolverCollection}>(
            self.CollectionPublicPath,
            target: self.CollectionStoragePath
        )

        // Create a Minter resource and save it to storage
        let minter <- create NFTMinter()
        self.account.save(<-minter, to: self.MinterStoragePath)

        emit ContractInitialized()
    }
}
