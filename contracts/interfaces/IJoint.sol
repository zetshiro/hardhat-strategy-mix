// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.4 <0.9.0;

import {IBaseStrategy} from './core/IBaseStrategy.sol';

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
