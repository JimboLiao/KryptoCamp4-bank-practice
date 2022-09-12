// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "forge-std/Script.sol";
import {BasicBank} from "../src/BasicBank.sol";
import {AdvanceBank} from "../src/AdvanceBank.sol";
import {StakingToken, RewardToken} from "../src/BankToken.sol";


contract DeployBankScript is Script {
   
    function setUp() public {
        
    }

    function run() public {
        vm.startBroadcast();

        StakingToken stToken = new StakingToken();
        BasicBank basicBank = new BasicBank(stToken);
        RewardToken rewardToken = new RewardToken();
        AdvanceBank advanceBank = new AdvanceBank(stToken, rewardToken);

        vm.stopBroadcast();
    }
}
