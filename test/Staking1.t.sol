// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import "src/StakingProxy.sol";

contract Staking1Test is Test {
    implementationV1 c;

    function setUp() public {
        c = new implementationV1();        
    }

    function testStake() public {
        uint value = 10 ether;
        vm.deal(0x884B3109CEc8932470FE7EAfF7Ba7b0758C35d2e, value);
        vm.prank(0x884B3109CEc8932470FE7EAfF7Ba7b0758C35d2e);
        c.stake{value: value}(value);
        assert(c.totalStakedValue() == value);
    }

    function testUnStake() public {
        uint value = 10 ether;
        vm.deal(0x884B3109CEc8932470FE7EAfF7Ba7b0758C35d2e, value);
        vm.startPrank(0x884B3109CEc8932470FE7EAfF7Ba7b0758C35d2e);
        assert(address(0x884B3109CEc8932470FE7EAfF7Ba7b0758C35d2e).balance == value);
        c.stake{value: value}(value);
        c.unStake(value);
        assert(c.totalStakedValue() == 0);
    }
}
