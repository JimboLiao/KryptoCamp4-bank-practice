// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/*
  建立一個 Bank 銀行
  在 web3 世界人人都可以當銀行家！我們想開張一間去中心化金融中心，簡易小而美的銀行

  使用者可以將我們發行的 Staking Token (ERC20代幣)存入銀行
  使用者執行定存，會開始計算 Reward 利息回饋
  使用者解除定存（withdraw），獲得 Reward 利息回饋

  Deposit 定存：實作 deposit function，可以將 Staking Token 存入 Bank 合約
  Withdraw 解除定存並提款，實作 withdraw function
  TimeLock 固定鎖倉期
*/
contract AdvanceBank {
    // 質押 Staking Token代幣
    IERC20 public stakingToken;
    // 利息獎勵代幣
    IERC20 public rewardToken;

    // 全部質押數量
    uint256 public totalSupply;
    // 個人質押數量
    mapping(address => uint256) public balanceOf;
    
    // 鎖倉時間
    uint256 public withdrawDeadline = 10 seconds;

    // 利息獎勵
    uint256 public rewardRate = 1;
    // 個人總利息
    mapping(address => uint256) public rewardOf;

    // 定存資料
    struct Deposit {
        uint256 amount; // 定存多少金額
        uint256 startTime; // 定存開始時間
        uint256 endTime; // 定存結束時間
    }

    mapping(address => Deposit[]) public depositOf;
    
    // 紀錄每個帳戶，操作 deposit, withdraw, getReward 最後更新的時間
    mapping(address => uint256) public lastUpdateTime;

    constructor(IERC20 _stakingToken, IERC20 _rewardToken) {
        stakingToken = _stakingToken;
        rewardToken = _rewardToken;
    }

    event WithdrawReward(address _account, uint256 _reward);

    // 計算利息，公式計算
    function earned() public view returns (uint256) {
        // 經過多少時間（秒）
        uint256 duration = block.timestamp - lastUpdateTime[msg.sender];
        // (你擁有多少顆 StakingToken * 時間 * rewardRate) + 目前獎勵利息有多少
        return balanceOf[msg.sender] * duration * rewardRate + rewardOf[msg.sender];
    }

    // 每次存提款、提領利息，都會呼叫他
    modifier updateReward() {
        // 1) 更新該帳戶的獎勵
        rewardOf[msg.sender] = earned();

        // 2) 更新最後的時間
        lastUpdateTime[msg.sender] = block.timestamp;
        _;
    }

    // 存款
    function deposit(uint256 _amount) external updateReward {
        // 1) 將 stakingToken 移轉到 BasicBank 合約
        stakingToken.transferFrom(msg.sender, address(this), _amount);

        // 2) 紀錄存款數量
        totalSupply += _amount;
        balanceOf[msg.sender] += _amount;

        // 3) 定存資訊
        depositOf[msg.sender].push(
            Deposit({
                amount: _amount,
                startTime: block.timestamp,
                endTime: block.timestamp + withdrawDeadline
            })
        );
    }

    // 解除定存
    function withdraw(uint256 _depositId) external updateReward {
        // 檢查：餘額需要大於 0
        require(balanceOf[msg.sender] > 0, "You have no balance to withdraw");

        Deposit[] storage deposits = depositOf[msg.sender];
        // 檢查條件: 必須超過鎖倉期才可以提領
        require(block.timestamp >= deposits[_depositId].endTime, "Withdrawal Period is not reached yet");
        // 檢查條件：定存ID 是否存在
        require(_depositId <= deposits.length, "Deposit ID not exist!!");

        uint256 amount = deposits[_depositId].amount;

        // 1) 獲得利息獎勵
        // rewardOf[msg.sender] += getReward(_depositId);

        // 2) 提款
        stakingToken.transfer(msg.sender, amount);
        totalSupply -= amount;
        balanceOf[msg.sender] -= amount;

        // 3) 移除此筆定存，移除陣列 deposits
        // 陣列往左移
        deposits[_depositId] = deposits[deposits.length - 1];
        deposits.pop();
    }

    // 利息 rewardToken 轉移給使用者
    function getReward() external updateReward {
        require(rewardOf[msg.sender] > 0, "You have no reward! sorry!");
        
        // 1) 取得目前的總利息，存進變數 reward
        uint256 reward = rewardOf[msg.sender];

        // 2) reward 將利息歸 0
        rewardOf[msg.sender] = 0;

        // 3) 利息用 rewardToken 方式獎勵給 User
        // 需要將 rewardToken 存到銀行，銀行才可以發放獎勵
        rewardToken.transfer(msg.sender, reward);

        // 4) 紀錄事件，使用者已經提領利息
        emit WithdrawReward(msg.sender, reward);
    }
}