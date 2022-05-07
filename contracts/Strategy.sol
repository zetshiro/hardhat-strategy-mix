// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

// @todo import the contract from the vault v3 package when it's published
import {BaseStrategy} from './core/BaseStrategy.sol';
import {IBaseStrategy} from './interfaces/core/IBaseStrategy.sol';

// @todo integrate with an actual protocol
// @todo complete the natspec doc in IBaseStrategy
contract Strategy is IBaseStrategy {
  constructor(address _vault) BaseStrategy(_vault) {}

  function name() external pure override returns (string memory) {
    // Add your own name here, suggestion e.g. "StrategyCreamYFI"`
    return 'Strategy<ProtocolName><TokenType>';
  }

  /// @notice try everything to withdraw from the underlying protocol.
  /// @dev actions can be paying withdrawal fees, unlocking fees, leaving rewards behind, selling at bad prices etc. or any other actions that should only be done under an emergency
  function _emergencyFreeFunds(uint256 _amountToWithdraw) internal override {}

  /// @note is it meant to say (on hackmd) invest funds into the vault instead?
  function _invest() internal override {}

  /// @notice adjust the position, e.g. claim and sell rewards, adjust debt ratios, close a position etc.
  function _harvest() internal override {}

  function _freeFunds(uint256 _amount) internal override returns (uint256 _amountFreed) {}

  /// @notice migrate all capital and positions to the new strategy
  function _migrate(address _newStrategy) internal override {}

  /// @notice check whether the harvest function can be called
  function harvestTrigger() external view override returns (bool) {}

  function investTrigger() external view override returns (bool) {}

  function investable() external view override returns (uint256 _minDebt, uint256 _maxDebt) {}

  // @todo discuss what the total assets of a strategy should be
  function totalAssets() external view override returns (uint256 _totalAssets) {}

  function withdrawable() external view override returns (uint256 _withdrawable) {}

  /// @note what are delegated assets of a strategy?
  function delegatedAssets() external view override returns (uint256 _delegatedAssets) {}
}
