const { assert } = require("chai");

const Crowdfunding = artifacts.require('Crowdfunding');

contract('Crowdfunding', accounts => {
    let result;
    let project = null
    beforeEach(async function () {
        contract = await Crowdfunding.deployed();
    });

    describe('startproject function', () => {
        it('should create new project', async () => {
            result = await contract.startProject(
                "Save the trees",
                "This is a project to protect the trees in the Axim forest",
                7,
                web3.utils.toWei('1', 'ether')
            );
            console.log(result);
        })
    });

    describe('returnAllProjects function', () => {
        it('should return all projects created', async () => {
            result = await contract.returnAllProjects();
            console.log(result);
        })
    });
});