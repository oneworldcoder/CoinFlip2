const Coinflip = artifacts.require("Coinflip");

module.exports = async function(deployer, network, accounts ) {
  await deployer.deploy(Coinflip);
  const instance = await Coinflip.deployed();
  await instance.addMoney({from: accounts[0], value: web3.utils.toWei("0.5", "ether")});

  console.log(`The contract balance is ${await instance.availableMoney()}`);
};
