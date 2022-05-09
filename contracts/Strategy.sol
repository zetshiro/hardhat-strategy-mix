// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

import {IERC20} from '@openzeppelin/contracts/interfaces/IERC20.sol';

// @todo import the contract from the vault v3 package when it's published
import {BaseStrategy} from './core/BaseStrategy.sol';

// @todo complete the natspec doc in IBaseStrategy
contract Strategy is BaseStrategy {
  constructor(address _vault) BaseStrategy(_vault) {}

  function name() external pure override returns (string memory) {
    // Add your own name here, suggestion e.g. "StrategyCreamYFI"`
    return 'Strategy<ProtocolName><TokenType>';
  }

  /// @notice try everything to withdraw from the underlying protocol.
  /// @dev actions can be paying withdrawal fees, unlocking fees, leaving rewards behind, selling at bad prices etc. or any other actions that should only be done under an emergency
  function _emergencyFreeFunds(uint256 _amountToWithdraw) internal override {}

  /// @dev if investTrigger is true, the keepers can call this function to invest the funds
  function _invest() internal override {
    // vault deposit: the vault receives the underlying token and the receipient will get the yield token in return
    // strategy invest: the strategy will invest the funds into the underlying protocol
  }

  /// @notice adjust the position, e.g. claim and sell rewards, close a position etc.
  function _harvest() internal override {}

  function _freeFunds(uint256 _amount) internal override returns (uint256 _amountFreed) {}

  /// @notice migrate all capital and positions to the new strategy
  function _migrate(address _newStrategy) internal override {}

  /// @notice check whether the harvest function can be called
  /// @dev the strategy can call harvest whenever it wants or when the strategy has accumulated x profits or if it has be y amount of time since the last harvest
  function harvestTrigger() external view override returns (bool) {}

  function investTrigger() external view override returns (bool) {}

  function investable() external view override returns (uint256 _minDebt, uint256 _maxDebt) {}

  /// @dev the amount of want token we have + the amount of the token we have deposited in the underlying protocol
  function totalAssets() external view override returns (uint256 _totalAssets) {}

  /// @dev withdraw is alias to free funds, so withdrawable is the amount of funds that we can free from the protocol
  function withdrawable() external view override returns (uint256) {
    return IERC20(want).balanceOf(address(this));
  }

  function delegatedAssets() external view override returns (uint256) {
    return 0;
  }
}
