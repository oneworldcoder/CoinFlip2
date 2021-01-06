const Coinflip = artifacts.require("Coinflip");
const truffleAssert = require("truffle-assertions");

contract("Coinflip", async function(accounts){
  let instance;

  before(async function() {
        instance = await Coinflip.deployed();
  });

  it("initial balance should be greater than 0", async function() {
        let balance = await instance.balance();
        assert(parseFloat(balance) > 0, "funds not added");
  });



});
