const Coinflip = artifacts.require("Coinflip");

module.exports = async function(deployer, network, accounts ) {
  await deployer.deploy(Coinflip);
  const instance = await Coinflip.deployed();
  await instance.addMoney({from: accounts[0], value: web3.utils.toWei("1", "ether")});

  console.log("The contract balance is ${await instance.balance}");
};
