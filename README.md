# fonkybats-nft-bo
The back office ERC721 contract management code for the project FonkyBats

## Start contract testing
### Deploy With Truffle directly (MacOS Apple M1 - node v16.13.0)
```
brew update
brew upgrade node
brew install nvm #Install nvm Node Version Manager
nvm install 16
nvm use 16
truffle compile #Compile contracts
export ALCHEMY_KEY="pXVRmm1TsgoZMNJGcG0zoiqPQJODSDvd";export MNEMONIC="casual normal diesel wrist okay quit figure blame output height pause veteran";export NETWORK="rinkeby"; DEPLOY_FONKYBATS=1 truffle migrate --network rinkeby #Deploy contracts on Rinkeby
```

## Test Keys Config
### Mnemonic
```casual normal diesel wrist okay quit figure blame output height pause veteran```

### MetaPass
```?9@Zw?RD%z662GxL```