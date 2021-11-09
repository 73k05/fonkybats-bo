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
export ALCHEMY_KEY="XXX";export MNEMONIC="";export NETWORK="rinkeby"; DEPLOY_FONKYBATS=1 DEPLOY_FONKYBATS_SALE=1 truffle migrate --network rinkeby #Deploy contracts on Rinkeby
```

You can use the `--reset` option to run all your migrations from the beginning