// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Kingnet is ReentrancyGuard, Ownable {
    // Define deposit pool structure
    struct DepositPool {
        uint256 amount; // Pool amount (in wei)
        uint256 num; // Number of deposits in this pool
        uint256 totalAmount; // Total amount deposited in this pool
    }

    struct DepositRecord {
        address owner;
        uint256 amount; // Pool amount (in wei)
        uint256 poolId; // Number of id in this pool
        uint256 timestamp;
    }

    // Store all pool information
    DepositPool[] public pools;
    DepositRecord[] public records;

    // Define deposit event
    event Deposit(
        address indexed owner,
        uint256 amount,
        uint256 poolId,
        uint256 timestamp,
        uint256 indexed recordId
    );

    error InvalidPoolIndex();
    error IncorrectDepositAmount();
    error InvalidRecordIndex();

    constructor() {
        transferOwnership(msg.sender);
        // Initialize deposit pools (amounts in ETH)
        pools.push(DepositPool(0.001 ether, 0, 0));
    }

    // Deposit function
    function deposit(uint256 _poolId) external payable nonReentrant {
        if (_poolId >= pools.length) {
            revert InvalidPoolIndex();
        }
        if (msg.value != pools[_poolId].amount) {
            revert IncorrectDepositAmount();
        }

        // Update pool statistics
        pools[_poolId].num++;
        pools[_poolId].totalAmount += msg.value;

        records.push(DepositRecord(msg.sender, msg.value, _poolId, block.timestamp));

        // Emit deposit event
        emit Deposit(msg.sender, msg.value, _poolId, block.timestamp, records.length - 1);
    }

    // Get specific pool information
    function getPoolInfo(
        uint256 _poolId
    ) external view returns (DepositPool memory) {
        if (_poolId >= pools.length) {
            revert InvalidPoolIndex();
        }
        return pools[_poolId];
    }

    // Get specific record information
    function getRecord(
        uint256 _recordId
    ) external view returns (DepositRecord memory) {
        if (_recordId >= records.length) {
            revert InvalidRecordIndex();
        }
        return records[_recordId];
    }

    // Get total number of pools
    function getPoolNum() external view returns (uint256) {
        return pools.length;
    }

    // Get total number of records
    function getRecordNum() external view returns (uint256) {
        return records.length;
    }

    // Add new deposit pool (only owner)
    function addPool(uint256 _amount) external onlyOwner {
        // Check if a pool with the same amount already exists
        for (uint256 i = 0; i < pools.length; i++) {
            require(pools[i].amount != _amount, "Pool amount already exists");
        }
        pools.push(DepositPool(_amount, 0, 0));
    }

    // Withdraw contract balance (only owner)
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        (bool success, ) = payable(owner()).call{value: balance}("");
        require(success, "Transfer failed");
    }
}
