// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.4 <0.9.0;

import '@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol';
import {IVaultAccessControl} from '../../interfaces/core/Vault/IVaultAccessControl.sol';

abstract contract VaultAccessControl is IVaultAccessControl, AccessControlUpgradeable {
  bytes32 public constant MASTER_ADMIN = keccak256('MASTER_ADMIN');
  bytes32 public constant GOVERNANCE = keccak256('GOVERNANCE');
  bytes32 public constant MANAGEMENT = keccak256('MANAGEMENT');
  bytes32 public constant GUARDIAN = keccak256('GUARDIAN');
  bytes32 public constant DEBT_OPERATOR = keccak256('DEBT_OPERATOR');
  bytes32 public constant STRATEGY_MANAGER = keccak256('STRATEGY_MANAGER');
  bytes32 public constant STRATEGY_REPORTER = keccak256('STRATEGY_REPORTER');
  bytes32 public constant SHUTDOWN_MANAGER = keccak256('SHUTDOWN_MANAGER');

  address public rewardsRecipient; // Rewards contract where Governance fees are sent to

  function __VaultAccessControl_init(
    address _masterAdmin,
    address _guardian,
    address _management
  ) internal onlyInitializing {
    _setRoleAdmin(MASTER_ADMIN, MASTER_ADMIN);
    _setRoleAdmin(GOVERNANCE, GOVERNANCE); // NOTE should governance be it's own admin?
    _setupRole(MASTER_ADMIN, _masterAdmin);
    _setupRole(GOVERNANCE, _masterAdmin);
    _setupRole(GUARDIAN, _guardian);
    _setupRole(SHUTDOWN_MANAGER, _masterAdmin);
    _setupRole(SHUTDOWN_MANAGER, _guardian);
    _setupRole(MANAGEMENT, _management);
    _setupRole(STRATEGY_MANAGER, _masterAdmin);
    _setupRole(STRATEGY_REPORTER, _masterAdmin);

    _setRoleAdmin(GOVERNANCE, GOVERNANCE); // NOTE should governance be it's own admin?
    _setRoleAdmin(GUARDIAN, GOVERNANCE);
    _setRoleAdmin(MANAGEMENT, GOVERNANCE);
    _setRoleAdmin(SHUTDOWN_MANAGER, MASTER_ADMIN);

    // the following roles are not set by default. should we set them?
    _setRoleAdmin(DEBT_OPERATOR, MASTER_ADMIN);
    _setRoleAdmin(STRATEGY_MANAGER, MASTER_ADMIN);
    _setRoleAdmin(STRATEGY_REPORTER, STRATEGY_MANAGER);
    // TODO Set proper role admins
  }
}
