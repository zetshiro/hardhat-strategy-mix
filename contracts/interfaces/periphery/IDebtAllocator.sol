// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.4 <0.9.0;

interface IDebtAllocator {
  function maxDebt(address _strategy) external view returns (uint256 _maxDebt);
}
