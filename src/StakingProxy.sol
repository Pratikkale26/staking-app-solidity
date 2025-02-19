// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";

contract StakingProxy is Ownable{
    uint public totalStakedValue;
    mapping(address => uint) public stakedBalance;

    address public implementation;

    constructor(address _implementation) Ownable(msg.sender){
        implementation = _implementation;
    }

    receive() external payable { }

    fallback() external payable {
        (bool success, ) = implementation.delegatecall(msg.data); 
        require(success, "Delegate call failed");
    }

    function setImplementation(address _newImplementation) public onlyOwner {
        implementation = _newImplementation;
    }
}

contract implementationV1 {
    uint public totalStakedValue;
    mapping(address => uint) public stakedBalance;

    function stake(uint _amount) public payable {
        require(_amount >= 0, "amount should be greater than or equal to 0");
        require(_amount == msg.value, "amount should be equal to the msg.value");
        totalStakedValue += _amount;
        stakedBalance[msg.sender] += _amount;
    }

    function unStake(uint _amount) public payable {
        require(stakedBalance[msg.sender] >= _amount, "Not enough balance");
        payable(msg.sender).transfer(_amount);
        totalStakedValue -= _amount;
        stakedBalance[msg.sender] -= _amount;
    }
}