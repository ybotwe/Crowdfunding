//SPDX-License-Identifier: ISC
pragma solidity ^0.8.4;

import './Project.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';

contract Crowdfunding{
    using SafeMath for uint256;



    /********************************************************************************************/
    /*                                       DATA VARIABLES                                     */
    /********************************************************************************************/
    Project[] private projects;



    /********************************************************************************************/
    /*                     EVENTS & CONTRACT FUNCTIONS                                          */
    /********************************************************************************************/

    //Event emitted when a new project is started 
    event ProjectStarted(
        address contractAddress,
        address projectStarter,
        string projectTitle,
        string projectDesc,
        uint256 deadline,
        uint256 goalAmount
    );


    /** @dev Function to start a new Project.
      *
      */
    function startProject(
        string calldata title,
        string calldata description,
        uint256 durationInDays,
        uint amountToRaise
    ) external {
        uint raiseUntil = block.timestamp.add(durationInDays.mul(1 days));
        Project newProject = new Project(msg.sender, title, description, raiseUntil, amountToRaise);
        projects.push(newProject);
        emit ProjectStarted(address(newProject), msg.sender, title, description, raiseUntil, amountToRaise);
    }


    /** @dev Function to get all projects' contract addresses.
      * @return A list of all projects' contract addreses
      */
    function returnAllProjects() external view returns(Project[] memory){
        return projects;
    }

}