const { assert } = require("chai");

const Project = artifacts.require('Project');

contract('Project', accounts => {
    let result;
    let project = null
    beforeEach(async function () {
        project = await Project.deployed();
    });

    describe('contribute function', () => {
        it('should change admins to top 5 highest bidders', async () => {
            await project.contribute({from: accounts[1], value: web3.utils.toWei('0.1', 'ether')})
            await project.contribute({from: accounts[2], value: web3.utils.toWei('0.2', 'ether')})
            await project.contribute({from: accounts[3], value: web3.utils.toWei('0.3', 'ether')})
            await project.contribute({from: accounts[4], value: web3.utils.toWei('0.4', 'ether')})
            await project.contribute({from: accounts[5], value: web3.utils.toWei('0.5', 'ether')})
            await project.contribute({from: accounts[6], value: web3.utils.toWei('0.6', 'ether')})
            await project.contribute({from: accounts[7], value: web3.utils.toWei('1', 'ether')})

    
            admins = await project.getAdmins();
            console.log(admins)
            expect(admins).deep.to.equal([accounts[6], accounts[7], accounts[3], accounts[4], accounts[5]]);
        })
    
    
        it('should contribute given amount', async () => {
            const previousBalance = await project.currentBalance()
            result = await project.contribute({ from: accounts[1], value: web3.utils.toWei('1', 'ether') })
            const currentBalance = await project.currentBalance()
            assert.isAbove(Number(currentBalance), Number(previousBalance), "Balance did not increase after contribution");
        })
    
        it('should change state when goal is successful', async () => {
            result = await project.contribute({ from: accounts[1], value: web3.utils.toWei('4', 'ether') })
            const currentState = await project.state()
            assert.equal(currentState, BigInt(1), "State did not change after goal was reached");
        })
    
    })

    describe('approveWithdrawal function', () => {
        it('should add approved admin into the accepted requests array', async () => {
            admins = await project.getAdmins();
            console.log(admins);
            await project.approveWithdrawal({from: accounts[7]});
            await project.approveWithdrawal({from: accounts[6]});
            await project.approveWithdrawal({from: accounts[4]});
            
            accepted = await project.getAcceptedRequests();
            console.log(accepted);
            expect(accepted).deep.to.equal([accounts[7], accounts[6], accounts[4]]);
        })


    })

    describe('withdraw function', () => {
        it('should withdraw funds from contract to creator', async () => {
            const previousBalance = await project.currentBalance()
            creator = await project.creator()
            var previousAccBalance = await web3.eth.getBalance(creator);
            result = await project.withdraw({from: accounts[0]})
            console.log(result)
            const currentBalance = await project.currentBalance()
            var currentAccBalance = await web3.eth.getBalance(creator);
            assert.isBelow(Number(currentBalance), Number(previousBalance))
            assert.isAbove(Number(currentAccBalance), Number(previousAccBalance))
        })

    })
})