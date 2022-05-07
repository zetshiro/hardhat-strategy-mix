// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

import {BaseStrategy} from './core/BaseStrategy.sol';
import {IBaseStrategy} from './interfaces/core/IBaseStrategy.sol';

contract Strategy is IBaseStrategy {
  constructor(address _vault) BaseStrategy(_vault) {}

  function name() external view override returns (string memory _name) {}

  function _emergencyFreeFunds(uint256 _amountToWithdraw) internal override {}

  function _invest() internal override {}

  function _harvest() internal override {}

  function _freeFunds(uint256 _amount) internal override returns (uint256 _amountFreed) {}

  function _migrate(address _newStrategy) internal override {}

  function harvestTrigger() external view override returns (bool) {}

  function investTrigger() external view override returns (bool) {}

  function investable() external view override returns (uint256 _minDebt, uint256 _maxDebt) {}

  function totalAssets() external view override returns (uint256 _totalAssets) {}

  function withdrawable() external view override returns (uint256 _withdrawable) {}

  function delegatedAssets() external view override returns (uint256 _delegatedAssets) {}
}
