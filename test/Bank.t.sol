// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/BasicBank.sol";
import "../src/BankToken.sol";

contract BankTest is Test {
    StakingToken stToken;
    BasicBank basicBank;
    uint256 constant amount = 50000;
    
    function setUp() public {
        stToken = new StakingToken();
        basicBank = new BasicBank(stToken);

        stToken.approve(address(basicBank), type(uint256).max);
    }

    function testDeposit() public {
        basicBank.deposit(amount);
        assertEq( basicBank.balanceOf(address(this)), amount );
    }

    function testWithdraw() public {
        testDeposit();
        skip(10);                   // skip 10 seconds
        basicBank.withdraw(0);      // index 0
        assertEq(basicBank.balanceOf(address(this)), 0 );
        assertEq(basicBank.rewardOf(address(this)), amount * 10);
    }

    function testReward(uint128 t) public {
        testDeposit();
        skip(t); // skip t seconds
        uint256 reward = basicBank.getAllReward();
        assertEq(reward, t * amount);
    }
    

    
}
