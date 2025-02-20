// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/StakingContract.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockPratikCoin is ERC20, IPratikCoin {
    constructor() ERC20("PratikCoin", "PC") {}

    function mint(address to, uint256 amount) external override {
        _mint(to, amount);
    }
}


// Test contract
contract StakingTest is Test {
    Staking staking;
    MockPratikCoin pratikCoin;
    address user1 = address(0xD2F046EBF794EC3480a3800360e476daE76CFC3C);
    address user2 = address(0x884B3109CEc8932470FE7EAfF7Ba7b0758C35d2e);

    function setUp() public {
        pratikCoin = new MockPratikCoin();
        staking = new Staking(pratikCoin);

        // sending users ETH
        vm.deal(user1, 10 ether);
        vm.deal(user2, 10 ether);
    }

    function testStake() public {
        vm.startPrank(user1);

        uint256 stakeAmount = 1 ether;

        // Stake ETH
        staking.stake{value: stakeAmount}(stakeAmount);

        // Validate state changes
        (uint256 stakedBalance,,) = staking.userInfo(user1);
        assertEq(stakedBalance, stakeAmount);
        assertEq(staking.totalStakedValue(), stakeAmount);

        vm.stopPrank();
    }

    function testUnstake() public {
        vm.startPrank(user1);

        uint256 stakeAmount = 1 ether;
        uint256 unstakeAmount = 0.5 ether;

        // Stake first
        staking.stake{value: stakeAmount}(stakeAmount);

        // Unstake
        staking.unstake(unstakeAmount);

        // Validate state changes
        (uint256 stakedBalance,,) = staking.userInfo(user1);
        assertEq(stakedBalance, stakeAmount - unstakeAmount);
        assertEq(staking.totalStakedValue(), stakeAmount - unstakeAmount);

        vm.stopPrank();
    }

    function testClaimRewards() public {
        vm.startPrank(user1);

        uint256 stakeAmount = 1 ether;

        // Stake
        staking.stake{value: stakeAmount}(stakeAmount);

        // increase time by 1000 seconds
        vm.warp(block.timestamp + 1000);

        // Claim rewards
        staking.claimRewards();

        // Validate reward balance in PratikCoin
        uint256 expectedRewards = (stakeAmount * 1000 * staking.REWARDS_PER_ETH_EVERY_SEC()) / 1e18;
        assertEq(pratikCoin.balanceOf(user1), expectedRewards);

        vm.stopPrank();
    }

}
