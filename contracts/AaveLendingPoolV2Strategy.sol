// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.4 <0.9.0;

import {IERC20} from '@openzeppelin/contracts/interfaces/IERC20.sol';

import {BaseStrategy} from './core/BaseStrategy.sol';

import {IVaultParameters} from './interfaces/core/Vault/IVaultParameters.sol';
import {IAaveLendingPoolV2} from './interfaces/IAaveLendingPoolV2.sol';

/// @notice the strategy receives profit from the gained interests of the loan
/// @dev see AaveLendingPoolV2USDCStrategy in the examples folder for creating a lending pool strategy for a specific "want" token
abstract contract AaveLendingPoolV2Strategy is BaseStrategy {
  IAaveLendingPoolV2 public immutable lendingPool;

  error InvalidAmount();

  constructor(address _vault, IAaveLendingPoolV2 _pool) BaseStrategy(_vault) {
    lendingPool = _pool;
  }

  /// @notice try everything to withdraw from the underlying protocol.
  /// @dev actions can be paying withdrawal fees, unlocking fees, leaving rewards behind, selling at bad prices etc. or any other actions that should only be done under an emergency
  function _emergencyFreeFunds(uint256 _amountToWithdraw) internal override {
    _freeFunds(_amountToWithdraw);
  }

  /// @dev if investTrigger is true, the keepers can call this function to invest the funds
  function _invest() internal override {
    uint256 _wantAmount = wantBalance();

    IERC20(want).approve(address(lendingPool), _wantAmount);
    lendingPool.deposit(want, _wantAmount, address(this), 0);
  }

  /// @notice adjust the position, e.g. claim and sell rewards, close a position etc.
  function _harvest() internal override canWithdrawFromLendingPool {
    lendingPool.withdraw(want, type(uint256).max, address(this));
  }

  /// @dev normally, we only close the position if we don't have any losses wihch is always the case with the Aave lending pool
  function _freeFunds(uint256 _amount) internal override canWithdrawFromLendingPool returns (uint256) {
    return lendingPool.withdraw(want, _amount, address(this));
  }

  /// @notice migrate all capital and positions to the new strategy
  function _migrate(address _newStrategy) internal override {
    address _aTokenAddress = aaveWantAddress();
    uint256 _aTokenBalance = aaveWantBalance();
    uint256 _wantAmount = wantBalance();

    IERC20(want).transfer(_newStrategy, _wantAmount);
    IERC20(_aTokenAddress).transfer(_newStrategy, _aTokenBalance);
  }

  /// @notice check whether the harvest function can be called
  /// @dev the strategy can call harvest whenever it wants or when the strategy has accumulated x profits or if it has be y amount of time since the last harvest
  function harvestTrigger() external view override returns (bool) {
    uint256 _currentTimeDelta = block.timestamp - IVaultParameters(vault).lastReport();
    return _currentTimeDelta >= 24 hours;
  }

  function investTrigger() external view override returns (bool) {
    return wantBalance() > 0;
  }

  function investable() external pure override returns (uint256 _minDebt, uint256 _maxDebt) {
    _minDebt = 0;
    _maxDebt = type(uint256).max;
  }

  /// @dev the amount of want token we have + the amount of the token we have deposited in the underlying protocol
  function totalAssets() external view override returns (uint256) {
    return wantBalance() + aaveWantBalance();
  }

  /// @notice the amount of funds we can withdraw from the strategy right now
  function withdrawable() external view override returns (uint256) {
    return wantBalance();
  }

  function delegatedAssets() external pure override returns (uint256) {
    return 0;
  }

  function wantBalance() public view returns (uint256) {
    return IERC20(want).balanceOf(address(this));
  }

  function aaveWantAddress() public view returns (address) {
    return lendingPool.getReserveData(want).aTokenAddress;
  }

  function aaveWantBalance() public view returns (uint256) {
    return IERC20(aaveWantAddress()).balanceOf(address(this));
  }

  modifier canWithdrawFromLendingPool() {
    if (aaveWantBalance() == 0) {
      revert InvalidAmount();
    }

    _;
  }
}
