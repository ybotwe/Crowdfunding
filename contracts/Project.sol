//SPDX-License-Identifier: ISC
pragma solidity ^0.8.4;

import '@openzeppelin/contracts/utils/math/SafeMath.sol';

contract Project {
    using SafeMath for uint256;

    /********************************************************************************************/
    /*                                       DATA VARIABLES                                     */
    /********************************************************************************************/

    address payable public creator;     // Address of the creator of the project
    uint public goal;    //Amount in wei that the project must reach to be successful
    uint public completedAt; //Time that project was successful
    uint public raisedBy; //Time of required for project to expire
    uint256 public currentBalance; //Amount currently raised
    string public title;    //Title of the project
    string public description;  //Description of the project
    State public state = State.Fundraising; //State of the project (default state: Fundraising)

    mapping(address => uint256) public contributions;   //Mapping to track the contributors of the project with 
                                                        //the amount contributed.
    uint constant private M = 3;    //Constant number of admins required to accept withdrawal
    uint256 private counter = 1; 


    /********************************************************************************************/
    /*                                       DATA STRUCTURES                                    */
    /********************************************************************************************/

    //Enum to show the state of the project
    enum State {
        Fundraising,
        Successful,
        Expired,
        Funded
    }


    /********************************************************************************************/
    /*                      FUNCTION MODIFIERS & CONSTRUCTOR                                    */
    /********************************************************************************************/

    /** 
        @dev Modifier to ensure that only the creator of the project calls that function.
    */
    modifier onlyCreator(){
        require(msg.sender == creator, "Only the project creator can call this function");
        _;
    }

    /** 
        @dev Modifier to check that the state of the project is at a specific state before calling the function.
        @param _state State at which the project must be in
    */
    modifier inState(State _state){
        require(state == _state);
        _;
    }

    /** 
        @dev Modifier to check for reentrancy.
    */
    modifier entrancyGuard(){
	
        counter= counter.add(1);
        uint256 localCounter = counter;
        _;
        require(counter == localCounter, "Reentrancy not permitted");
    }       

    
    constructor(
        address projectCreator,
        string memory projectTitle,
        string memory projectDescription,
        uint timeOfCompletion,
        uint projectGoal
    )  
    {
        creator = payable(projectCreator);
        title = projectTitle;
        description = projectDescription;
        raisedBy = timeOfCompletion;
        goal = projectGoal;
    }


    /********************************************************************************************/
    /*                     EVENTS & CONTRACT FUNCTIONS                                          */
    /********************************************************************************************/

    // Event that will be emitted whenever funding will be received
    event FundingReceived(address contributor, uint amount, uint currentTotal);

    //Event that will be emitted when the creator of the project has withdrawn funds
    event CreatorFunded(address recipient, uint amount);


    /** 
        @dev Function to fund a certain project.
        1. Check if the person sending funds is not the creator of the project
        2. Increase currentBalance and the contribution of the address sending funds 
        3. If the currentBalance is greater than or equal to goal make appropriate state changes 
        and set completed time to current time.
        4. if current time is greater than raisedBy(time set for fundraising to be over) changed state to expired
        5. Next we check if the length of the admins(highest contributors list) is less than 5. 
        6. If so, we push the address of the sender else we calculate the least contributing member of admins
           and replace it with the msg.sender.
    */
    function contribute() public inState(State.Fundraising) entrancyGuard payable {
        require(msg.sender != creator);
        
        
        contributions[msg.sender] = contributions[msg.sender] + msg.value;
        currentBalance += msg.value;
        
        

        if(currentBalance >= goal){
            state = State.Successful;
            completedAt = block.timestamp;
        } else if (block.timestamp > raisedBy){
            state = State.Expired;
            completedAt = block.timestamp;
        }

        emit FundingReceived(msg.sender, msg.value, currentBalance);
    }


    /** 
        @dev Function to send received funds to the creator of the project.
        1. Basically stores the current balance in a temporary variable,
        2. Changes current balance to zero. 
        3. Uses .call to send funds to creator (.call was recommended over .send and .transfer 
        see https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now).
        4. Check if call was successful then emit event, if not, reset value of currentBalance

    */
    function withdraw() external inState(State.Successful) onlyCreator entrancyGuard {
        require(msg.sender == creator, "Only creator can call this function");
        uint256 totalRaised = currentBalance;
        creator.transfer(totalRaised);
        currentBalance = 0;
    }


    /** 
    * @dev Function to retrieve donated amount when a project expires.
    */
    function getRefund() external inState(State.Expired) {
        require(contributions[msg.sender] > 0);

        uint amountToRefund = contributions[msg.sender];
        payable(msg.sender).transfer(amountToRefund);
        contributions[msg.sender] = 0; 
    }

    /** 
      *   @dev Function to get specific information about the project.
    */
    function getDetails() public view returns(
        address payable projectStarter,     
        string  memory projectTitle,   
        string  memory projectDesc,
        uint  deadline,
        uint256  balance, 
        uint256  projectGoal,
        State currentState
    ){
        projectStarter = creator;
        projectTitle = title;
        projectDesc = description;
        deadline = raisedBy;
        balance = currentBalance;
        projectGoal = goal;
        currentState = state;
    }


    /** 
      *   @dev  Function to check balance of project.
    */
    function getBalance() public view returns (uint){
        return address(this).balance;
    }



}