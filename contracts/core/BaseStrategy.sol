// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.4 <0.9.0;

import {SafeERC20} from '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {IVaultAccessControl} from '../interfaces/core/Vault/IVaultAccessControl.sol';
import {IVaultStrategyManager} from '../interfaces/core/Vault/IVaultStrategyManager.sol';
import {IDebtAllocator} from '../interfaces/periphery/IDebtAllocator.sol';
import {IBaseStrategy} from '../interfaces/core/IBaseStrategy.sol';
import {IVaultParameters} from '../interfaces/core/Vault/IVaultParameters.sol';

/**
 * @title Yearn Base Strategy
 * @author yearn.finance
 * @notice
 *  BaseStrategy implements all of the required functionality to interoperate
 *  closely with the Vault contract. This contract should be inherited and the
 *  abstract methods implemented to adapt the Strategy to the particular needs
 *  it has to create a return.
 *
 */

abstract contract BaseStrategy is IBaseStrategy {
  using SafeERC20 for IERC20;

  // TODO: KEEP ROLES IN VAULT only?
  bytes32 public constant GOVERNANCE = keccak256('GOVERNANCE');
  bytes32 public constant KEEPER = keccak256('KEEPER');
  // TODO: think of another name for mgmt
  bytes32 public constant MANAGEMENT = keccak256('MANAGEMENT');

  address public override vault;
  address public override want;

  constructor(address _vault) {
    _initialize(_vault);
  }

  /**
   * @notice
   *  Initializes the Strategy, this is called only once, when the
   *  contract is deployed.
   * @dev `_vault` should implement `VaultAPI`.
   * @param _vault The address of the Vault responsible for this Strategy.
   */
  function _initialize(address _vault) internal {
    if (address(want) != address(0)) revert StrategyAlreadyInitialized();

    vault = _vault;
    want = IVaultParameters(vault).token();
    // using approve since initialization is only called once
    IERC20(want).approve(_vault, type(uint256).max); // Give Vault unlimited access (might save gas)
    // TODO: there is risk of running out of allowance ^^
  }

  function _onlyEmergencyAuthorized() internal view {
    if (IVaultAccessControl(vault).hasRole(GOVERNANCE, msg.sender) || IVaultAccessControl(vault).hasRole(MANAGEMENT, msg.sender)) {
      return;
    }
    revert NoAccess();
  }

  function _onlyKeepers() internal view {
    if (
      IVaultAccessControl(vault).hasRole(KEEPER, msg.sender) ||
      IVaultAccessControl(vault).hasRole(GOVERNANCE, msg.sender) ||
      IVaultAccessControl(vault).hasRole(MANAGEMENT, msg.sender)
    ) {
      return;
    }

    revert NoAccess();
  }

  function _onlyGovernance() internal view {
    if (IVaultAccessControl(vault).hasRole(GOVERNANCE, msg.sender)) return;

    revert NoAccess();
  }

  function _onlyVault() internal view {
    if (msg.sender == vault) return;
    revert NoAccess();
  }

  modifier onlyEmergencyAuthorized() {
    _onlyEmergencyAuthorized();
    _;
  }

  modifier onlyGovernance() {
    _onlyGovernance();
    _;
  }

  modifier onlyKeepers() {
    _onlyKeepers();
    _;
  }

  modifier onlyVault() {
    _onlyVault();
    _;
  }

  function apiVersion() public pure override returns (uint256) {
    return 1000;
  }

  function harvest() external override onlyKeepers {
    _harvest();
  }

  function invest() external override onlyKeepers {
    _invest();
  }

  function freeFunds(uint256 _amount) external override onlyVault returns (uint256 amountFreed) {
    return _freeFunds(_amount);
  }

  function migrate(address _newStrategy) external onlyVault {
    _migrate(_newStrategy);
  }

  function emergencyFreeFunds(uint256 _amount) external override onlyVault {
    _emergencyFreeFunds(_amount);
  }

  function _harvest() internal virtual;

  function _invest() internal virtual;

  function _freeFunds(uint256 _amount) internal virtual returns (uint256 amountFreed);

  function _emergencyFreeFunds(uint256 _amount) internal virtual;

  function _migrate(address _newStrategy) internal virtual;

  // TODO: protected tokens

  // TODO: sweep
}
