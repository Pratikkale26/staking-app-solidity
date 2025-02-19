// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import "src/PratikCoin.sol";

contract ERC20ContractTest is Test {
    PratikCoin c;

    function setUp() public {
        c = new PratikCoin(address(this));
    }

    function testMint() public {
        uint value = 10;
        c.mint(address(this), value);

        assert(c.balanceOf(address(this)) == value);
    }

    function testFailMint() public {
        vm.startPrank(0x884B3109CEc8932470FE7EAfF7Ba7b0758C35d2e);
        c.mint(address(this), 10);
    }
}