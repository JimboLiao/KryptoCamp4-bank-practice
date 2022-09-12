// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/BasicBank.sol";
import "../src/AdvanceBank.sol";
import "../src/BankToken.sol";

contract BankTest is Test {
    StakingToken stToken;
    BasicBank basicBank;
    RewardToken rewardToken;
    AdvanceBank advanceBank;

    // uint256 constant AMOUNT = 25000;
    
    function setUp() public {
        stToken = new StakingToken();
        basicBank = new BasicBank(stToken);
        rewardToken = new RewardToken();
        advanceBank = new AdvanceBank(stToken, rewardToken);

        stToken.approve(address(basicBank), type(uint256).max);
        stToken.approve(address(advanceBank), type(uint256).max);
        
        rewardToken.transfer(address(advanceBank), rewardToken.balanceOf(address(this)));
        assertEq(rewardToken.balanceOf(address(advanceBank)), 100 * 1e18);
    }

    function testDeposit(uint256 _amount) public {
        vm.assume(_amount > 0 && _amount <= stToken.balanceOf(address(this)));
        
        basicBank.deposit(_amount);
        assertEq( basicBank.balanceOf(address(this)), _amount );

        
    }

    function testDepositAdvanced(uint256 _amount) public {
        vm.assume(_amount > 0 && _amount <= stToken.balanceOf(address(this)));

        advanceBank.deposit(_amount);
        assertEq( advanceBank.balanceOf(address(this)), _amount );
    }

    function testWithdraw(uint256 _amount, uint8 t) public {
        testDeposit(_amount);
        
        vm.assume(t >= 10);        // at least skip 10 seconds
        skip(t);                   // skip 10 seconds
        
        basicBank.withdraw(0);      // index 0
        assertEq(basicBank.balanceOf(address(this)), 0 );
        assertEq(basicBank.rewardOf(address(this)), _amount * t);
    }

    function testWithdrawAdvanced(uint256 _amount, uint8 t) public{
        testDepositAdvanced(_amount);
        
        vm.assume(t >= 10);        // at least skip 10 seconds
        skip(t);                   // skip 10 seconds

        assertEq(rewardToken.balanceOf(address(this)), 0);
        advanceBank.withdraw(0); 
        assertEq(advanceBank.balanceOf(address(this)), 0 );
        advanceBank.getReward();
        assertEq(rewardToken.balanceOf(address(this)), _amount * t);
    }

    function testReward(uint256 _amount, uint8 t) public {
        testDeposit(_amount);

        vm.assume(t >= 10);
        skip(t);     // skip t seconds
        
        uint256 reward = basicBank.getAllReward();
        assertEq(reward, t * _amount);

    }

    function testRewardAdvanced(uint256 _amount, uint8 t) public{
        testDepositAdvanced(_amount);

        vm.assume(t >= 10);
        skip(t);     // skip t seconds

        advanceBank.getReward();
        uint256 advanceReward = rewardToken.balanceOf(address(this));
        assertEq(advanceReward, t * _amount);
    }
    

    
}
