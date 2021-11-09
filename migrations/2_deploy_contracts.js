const FonkyBat = artifacts.require("./FonkyBat.sol");
const FonkyBatFactory = artifacts.require("./FonkyBatFactory.sol");

// If you want to hardcode what deploys, comment out process.env.X and use
// true/false;
const DEPLOY_ALL = process.env.DEPLOY_ALL;

// Note that we will default to this unless DEPLOY_ACCESSORIES is set.
// This is to keep the historical behavior of this migration.
const DEPLOY_FONKYBATS = process.env.DEPLOY_FONKYBATS || DEPLOY_ALL;
const DEPLOY_FONKYBATS_SALE = process.env.DEPLOY_FONKYBATS_SALE || DEPLOY_ALL;

module.exports = async (deployer, network) => {
  // OpenSea proxy registry addresses for rinkeby and mainnet. Whitelist the proxy accounts of OpenSea users
  // so that they are automatically able to trade any item on OpenSea (without having to pay gas for an additional approval).
  let proxyRegistryAddress;
  if (network === 'rinkeby') {
    proxyRegistryAddress = "0xf57b2c51ded3a29e6891aba85459d600256cf317";
  } else {
    proxyRegistryAddress = "0xa5409ec958c83c3f309868babaca7c86dcb077c1";
  }

  //Owner base contract
  if (DEPLOY_FONKYBATS) {
    await deployer.deploy(FonkyBat, proxyRegistryAddress, {gas: 5000000});
  }

  //Factory secondary contract allowing pre-sale and OTA minting
  if (DEPLOY_FONKYBATS_SALE) {
    await deployer.deploy(FonkyBatFactory, proxyRegistryAddress, FonkyBat.address, {gas: 7000000});
    const fonkybat = await FonkyBat.deployed();
    await fonkybat.transferOwnership(FonkyBatFactory.address);
  }
};
