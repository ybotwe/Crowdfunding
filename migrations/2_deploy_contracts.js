const Project = artifacts.require("Project");

module.exports = function (deployer, network, accounts) {
  
  deployer.deploy(Project, accounts[0], "New Project", "Description for new project" , 1642887000, web3.utils.toWei('5', 'ether'));
};
