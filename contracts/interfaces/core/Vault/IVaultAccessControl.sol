// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.4 <0.9.0;

import '@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol';

interface IVaultAccessControl is IAccessControlUpgradeable {
  error InvalidRewardsRecipient();
  error NoAccess();

  event UpdateRewardsRecipient(address rewardsRecipient); // New active rewards recipient

  function MASTER_ADMIN() external view returns (bytes32 _masterAdmin);

  function GOVERNANCE() external view returns (bytes32 _governance);

  function MANAGEMENT() external view returns (bytes32 _management);

  function GUARDIAN() external view returns (bytes32 _guardian);

  function DEBT_OPERATOR() external view returns (bytes32 _debtOperator);

  function STRATEGY_MANAGER() external view returns (bytes32 _strategyManager);

  function STRATEGY_REPORTER() external view returns (bytes32 _strategyReporter);

  function rewardsRecipient() external view returns (address _rewardsRecipient);

  function setRewards(address _rewardsRecipient) external;
}
