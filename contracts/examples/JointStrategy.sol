// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.4 <0.9.0;

import {SafeERC20} from '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';

import {BaseStrategy} from '../core/BaseStrategy.sol';
import {IBaseStrategy} from '../interfaces/core/IBaseStrategy.sol';

// @note check out the implementation of the joint strategy in https://github.com/fp-crypto/joint-strategy/blob/master/contracts/Joint.sol
interface IJoint is IBaseStrategy {
  /// @notice withdraw the funds from the underlying protocol and return it back to the depositor
  function closePositionReturnFunds() external;

  /// @notice invest the funds in the underlying protocol
  function openPosition() external;

  function providerA() external view returns (address);

  function providerB() external view returns (address);

  function estimatedTotalAssetsInToken(address _token) external view returns (uint256);

  function migrateProvider(address _newProvider) external;

  function shouldEndEpoch() external view returns (bool);

  function shouldStartEpoch() external view returns (bool);

  function dontInvestWant() external view returns (bool);

  function harvestTrigger() external view returns (bool);
}

contract JoinStrategy is BaseStrategy {
  using SafeERC20 for IERC20;

  address public joint;
  address public healthcheck;
  bool public forceLiquidate;

  constructor(address _vault) BaseStrategy(_vault) {}

  // SETTERS
  function setJoint(address _joint) external onlyGovernance {
    joint = _joint;
  }

  function setForceLiquidate(bool _forceLiquidate) external onlyGovernance {
    forceLiquidate = _forceLiquidate;
  }

  // MAIN STRATEGY'S FUNCTIONS
  function name() external view override returns (string memory) {
    return string(abi.encodePacked('Strategy', 'Joint', 'DAI'));
  }

  // @notice Amount idle here + assets in Joint (includes current profit!)
  function totalAssets() public view override returns (uint256 _totalAssets) {
    return IERC20(want).balanceOf(address(this)) + IJoint(joint).estimatedTotalAssetsInToken(address(want));
  }

  function investable() public view override returns (uint256 _minDebt, uint256 _maxDebt) {
    // @note we can cap max amount to want of whatever the other provider is managing
    return (0, type(uint256).max);
  }

  /// @dev Only withdrawable funds are those in current strategy, as the strategy should not unwind position to cover withdraws
  function withdrawable() public view override returns (uint256 _withdrawableAmount) {
    return IERC20(want).balanceOf(address(this));
  }

  /// @notice Strategy will deposit tokens to Joint Smart Contract that handles all complex logic for both providers
  function _invest() internal override {
    if (IJoint(joint).dontInvestWant()) {
      return;
    }

    uint256 wantBalance = IERC20(want).balanceOf(address(this));
    if (wantBalance > 0) {
      IERC20(want).transfer(joint, wantBalance);
    }

    IJoint(joint).openPosition();
  }

  // This function checks if "invest()" needs to be called
  function investTrigger() external view override returns (bool) {
    return _investTrigger();
  }

  function _freeFunds(uint256 _amount) internal override returns (uint256 _freedFunds) {
    // Strategy should not close the position to serve vault debt unless it's an emergency
    return IERC20(want).balanceOf(address(this));
  }

  function _emergencyFreeFunds(uint256 _amountToWithdraw) internal override onlyEmergencyAuthorized {
    IJoint(joint).closePositionReturnFunds();
  }

  // HARVEST
  function _harvest() internal override onlyKeepers {
    // if it is time to close the epoch, close it
    if (IJoint(joint).shouldEndEpoch()) {
      IJoint(joint).closePositionReturnFunds();
    }

    // if Joint is asking to be harvested (aka sell rewards), harvest it
    if (IJoint(joint).harvestTrigger()) {
      IJoint(joint).harvest();
    }
  }

  function harvestTrigger() external view override returns (bool) {
    bool _shouldEndEpoch = IJoint(joint).shouldEndEpoch();
    bool _harvestTrigger = IJoint(joint).harvestTrigger();

    return _shouldEndEpoch || _harvestTrigger;
  }

  function _investTrigger() internal view returns (bool) {
    uint256 wantBalance = IERC20(want).balanceOf(address(this));
    bool _shouldStartEpoch = IJoint(joint).shouldStartEpoch();

    return wantBalance > 0 && _shouldStartEpoch;
  }

  function _migrate(address _newStrategy) internal override {}

  function delegatedAssets() external view override returns (uint256 _delegatedAssets) {
    return 0;
  }
}
