var Pledgeo = artifacts.require("./Pledgeo.sol");

module.exports = function(deployer) {
  deployer.deploy(Pledgeo);
};
