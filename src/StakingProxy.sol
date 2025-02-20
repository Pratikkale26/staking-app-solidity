// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IPratikCoin {
    function mint(address to, uint amount) external;
}

contract StakingProxy is Ownable{
    mapping(address => uint) public stakedBalance;
    uint public totalStakedValue;
    
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


contract implementationV3 {
    mapping(address => uint) public stakedBalance;
    uint public totalStakedValue;
    uint public constant REWARDS_PER_ETH_EVERY_SEC = 1e15; // 0.001 ETH per second- 10**15 wei

    IPratikCoin public pratikCoin;

    struct UserInfo {
        uint stakedBalance;
        uint unclaimedReward;
        uint lastUpdate;
    }
    mapping(address => UserInfo) public userInfo;

    constructor(IPratikCoin _token) {
        pratikCoin = _token;
    }

    // made function so code duplication doesn't happens
    function _updateRewards(address _user) internal {
        UserInfo storage user = userInfo[_user];

        if (user.lastUpdate == 0) {
            user.lastUpdate = block.timestamp;
            return;
        }

        uint256 timeDiff = block.timestamp - user.lastUpdate;
        if (timeDiff == 0) {
            return;
        }

        uint256 additionalReward = (user.stakedBalance * timeDiff * REWARDS_PER_ETH_EVERY_SEC) / 1e18; // dividing  will prevent overflow

        user.unclaimedReward += additionalReward;
        user.lastUpdate = block.timestamp;
    }


    function stake(uint256 _amount) external payable {
        require(_amount > 0, "Cannot stake 0 ETH");
        require(msg.value == _amount, "ETH amount mismatch");

        _updateRewards(msg.sender);

        userInfo[msg.sender].stakedBalance += _amount;
        totalStakedValue += _amount;
    }

    function unstake(uint _amount) public payable {
        require(_amount > 0, "Cannot unstake 0 ETH");
        UserInfo storage user = userInfo[msg.sender];
        require(user.stakedBalance >= _amount, "Not enough staked balance");

        _updateRewards(msg.sender);

        user.stakedBalance -= _amount;
        totalStakedValue -= _amount;

        // payable(msg.sender).transfer(_amount); // it may fail for certain addresses
        (bool success, ) = payable(msg.sender).call{value: _amount}("");
        require(success, "Tranfter failed, unstaking unsuccessful");
    }

    function claimRewards() public {
        _updateRewards(msg.sender);
        UserInfo storage user = userInfo[msg.sender];

        uint rewards = user.unclaimedReward;
        require(rewards > 0, "you dont have any rewards to claim");

        pratikCoin.mint(msg.sender, rewards);
        user.unclaimedReward = 0;
    }

    function getRewards() public view returns (uint) {
        uint256 timeDiff = block.timestamp - userInfo[msg.sender].lastUpdate;
        if (timeDiff == 0) {
            return userInfo[msg.sender].unclaimedReward;
        }

        return (userInfo[msg.sender].stakedBalance * timeDiff * REWARDS_PER_ETH_EVERY_SEC) / 1e18 + userInfo[msg.sender].unclaimedReward;
    }

}




// // --------
// contract implementationV2 {
//     uint public totalStakedValue;
//     mapping(address => uint) public stakedBalance;
//     mapping(address => uint) unclaimRewards;
//     mapping(address => uint) lastUpdateTime;

//     function stake(uint _amount) public payable {
//         require(_amount >= 0, "amount should be greater than or equal to 0");
//         require(_amount == msg.value, "amount should be equal to the msg.value");
//         totalStakedValue += _amount;

//         if(!lastUpdateTime[msg.sender]) {
//             lastUpdateTime[msg.sender] = block.timestamp;
//         }else{
//             unclaimRewards[msg.sender] += (block.timestamp- lastUpdateTime[msg.sender]) * stakedBalance[msg.sender];
//             lastUpdateTime[msg.sender] = block.timestamp; 
//         }
//         stakedBalance[msg.sender] += _amount;
//     }

//     function unStake(uint _amount) public payable {
//         require(stakedBalance[msg.sender] >= _amount, "Not enough balance");

//         unclaimRewards[msg.sender] += (block.timestamp- lastUpdateTime[msg.sender]) * stakedBalance[msg.sender];
//         lastUpdateTime[msg.sender] = block.timestamp; 

//         payable(msg.sender).transfer(_amount);
//         totalStakedValue -= _amount;
//         stakedBalance[msg.sender] -= _amount;


//     }

//     // can see what are the rewards
//     function getRewards(address _address) public view returns(uint) {
//         uint currRewards = unclaimRewards[_address];
//         uint updateTime = lastUpdateTime[_address];
//         uint newRewards = (block.timestamp - updateTime) * stakedBalance[_address];
//         return currRewards + newRewards;
//     }

//     // can claim the reward
//     function claimRewards() public payable {
//         uint currRewards = unclaimRewards[msg.sender];
//         uint updateTime = lastUpdateTime[msg.sender];
//         uint newRewards = (block.timestamp - updateTime) * stakedBalance[msg.sender];

//         // transfer currRewards + newRewards to the user

//         unclaimRewards[msg.sender] = 0;
//         lastUpdateTime[msg.sender] = block.timestamp;
//     }

// }

// contract implementationV1 {
//     uint public totalStakedValue;
//     mapping(address => uint) public stakedBalance;

//     function stake(uint _amount) public payable {
//         require(_amount >= 0, "amount should be greater than or equal to 0");
//         require(_amount == msg.value, "amount should be equal to the msg.value");
//         totalStakedValue += _amount;
//         stakedBalance[msg.sender] += _amount;
//     }

//     function unStake(uint _amount) public payable {
//         require(stakedBalance[msg.sender] >= _amount, "Not enough balance");
//         payable(msg.sender).transfer(_amount);
//         totalStakedValue -= _amount;
//         stakedBalance[msg.sender] -= _amount;
//     }
// }
