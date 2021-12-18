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

    address[5] public admins;         //List of top 5 contributors
    address[] public acceptedRequests; //List of admins who have accepted withdrawal
    uint constant private M = 3;    //Constant number of admins required to accept withdrawal
    uint256 private index = 0;
    uint256 private threshold = type(uint256).max;
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

        if(index < 5 && admins[index] == address(0)){
            admins[index] = msg.sender;
            index += 1;
            if(msg.value < threshold){
                threshold = msg.value;
            }
        } else {
            if(msg.value > threshold){
                for(uint i = 0; i < 5; i++){
                    if (admins[i] == msg.sender){
                        return;
                    } else{
                        if(contributions[admins[i]] <= msg.value && contributions[admins[i]] == threshold){
                            admins[i] = msg.sender;
                            threshold = type(uint256).max;
                        }
                    }
                    
                }
                for(uint i = 0; i < 5; i++){
                    uint value = contributions[admins[i]];
                    if(value < threshold){
                        threshold = value;
                    }
                }
            }
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
    function withdraw() external inState(State.Successful) onlyCreator entrancyGuard payable returns (bool){
        require(msg.sender == creator, "Only creator can call this function");
        require(acceptedRequests.length >=  M, "3 or more of the top 5 contributors need to accept withdrawal");
        uint256 totalRaised = currentBalance;
        currentBalance = 0;
        (bool success, ) = creator.call{value: totalRaised}("");
        if(success){
            state = State.Funded;
            emit CreatorFunded(creator, totalRaised);
            return true;
        } else {
            currentBalance = totalRaised;
            return false;
        }
       
    }
    /** 
    * @dev Function to retrieve donated amount when a project expires.
    */
    function getRefund() external inState(State.Expired) payable returns(bool){
        require(contributions[msg.sender] > 0);

        uint amountToRefund = contributions[msg.sender];
        contributions[msg.sender] = 0; 

        (bool success, ) = msg.sender.call{value: msg.value}("");
        if (success) {
            currentBalance = currentBalance.sub(amountToRefund);
        } else {
            contributions[msg.sender] = amountToRefund;
        }
        return success;
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
        State currentState,
        uint256 currentIndex,
        uint256 thresholdVal
    ){
        projectStarter = creator;
        projectTitle = title;
        projectDesc = description;
        deadline = raisedBy;
        balance = currentBalance;
        projectGoal = goal;
        currentState = state;
        currentIndex = index;
        thresholdVal = threshold;
    }

    /** 
      *   @dev Internal Function to check whether item is in a list.
    */
    function contains(address userAddress, address[5] memory list) internal pure returns(bool) {
        for(uint i = 0; i < 5; i++){
            if(list[i] == userAddress){
                return true;
            }
        }
        return false;
    }

    /** 
      *   @dev Function to approve withdrawal for the project from the top 5 contributors.
    */
    function approveWithdrawal() inState(State.Successful) external {
        require(contains(msg.sender, admins), "User not part of the top 5 contributors");
        acceptedRequests.push(msg.sender);
    }

    /*
    * @dev Function to get list of highest contributors
    */
    function getAdmins() external view returns(address[5] memory){
        return admins;
    }


    /*
    * @dev Function to get list approved withdrawal requests
    */
    function getAcceptedRequests() external view returns(address[] memory){
        return acceptedRequests;
    }


}