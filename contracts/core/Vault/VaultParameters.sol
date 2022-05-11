// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.4 <0.9.0;

import {VaultAccessControl} from './VaultAccessControl.sol';
import {IYieldToken} from '../../interfaces/core/IYieldToken.sol';
import {IVaultParameters} from '../../interfaces/core/Vault/IVaultParameters.sol';

abstract contract VaultParameters is IVaultParameters, VaultAccessControl {
  string public constant API_VERSION = '0.5.0';

  uint256 public constant MAX_BPS = 10_000; // 100%, or 10k basis points

  uint256 public depositLimit; // Limit for totalAssets the Vault can hold
  uint256 public totalDebt; // Amount of tokens that all strategies have borrowed
  uint256 public totalIdle; // Amount of tokens that are on the vault
  uint256 public lastReport; // block.timestamp of last report
  uint256 public lockedProfit; // how much profit is locked and cant be withdrawn
  uint256 public previousHarvestTimeDelta; // how much time elapsed between last and previous report

  address public yieldToken;
  address public token;

  address public debtAllocator;
  address public healthCheck;

  string public name;
  string public symbol;

  // Governance Fee for performance of Vault (given to `rewards`)
  uint256 public performanceFee;

  bool public emergencyShutdown;

  mapping(address => StrategyParams) internal _strategies;

  function strategies(address _strategy) external view override returns (StrategyParams memory) {
    return _strategies[_strategy];
  }

  function setHealthCheck(address _healthCheck) external onlyRole(GOVERNANCE) {
    emit UpdateHealthCheck(_healthCheck);
    healthCheck = _healthCheck;
  }

  function setDebtAllocator(address _debtAllocator) external onlyRole(GOVERNANCE) {
    debtAllocator = _debtAllocator;
  }

  function setRewards(address _rewardsRecipient) external onlyRole(GOVERNANCE) {
    /**
    @notice
        Changes the rewardsRecipient address. Any distributed rewards
        will cease flowing to the old address and begin flowing
        to this address once the change is in effect.

        This will not change any Strategy reports in progress, only
        new reports made after this change goes into effect.

        This may only be called by governance.
    @param rewardsRecipient The address to use for collecting rewardsRecipient.
    */
    if (_rewardsRecipient == address(this) || _rewardsRecipient == address(0x0)) revert InvalidRewardsRecipient();
    rewardsRecipient = _rewardsRecipient;
    emit UpdateRewardsRecipient(rewardsRecipient);
  }

  function apiVersion() external pure returns (string memory) {
    /**
    @notice
        Used to track the deployed version of this contract. In practice you
        can use this version number to compare with Yearn's GitHub and
        determine which version of the source matches this deployed contract.
    @dev
        All strategies must have an `apiVersion()` that matches the Vault's
        `API_VERSION`.
    @return API_VERSION which holds the current version of this contract.
     */
    return API_VERSION;
  }

  function setPerformanceFee(uint256 _fee) external onlyRole(GOVERNANCE) {
    /**
    @notice
        Used to change the value of `performanceFee`.

        Should set this value below the maximum strategist performance fee.

        This may only be called by governance.
    @param fee The new performance fee to use.
    */
    if (_fee > performanceFeeThreshold()) revert PerformanceFeeExceedThreshold();

    performanceFee = _fee;
    emit UpdatePerformanceFee(_fee);
  }

  function setDepositLimit(uint256 _limit) external onlyRole(GOVERNANCE) {
    /**
    @notice
        Changes the maximum amount of tokens that can be deposited in this Vault.

        Note, this is not how much may be deposited by a single depositor,
        but the maximum amount that may be deposited across all depositors.

        This may only be called by governance.
    @param limit The new deposit limit to use.
    */
    depositLimit = _limit;
    emit UpdateDepositLimit(_limit);
  }

  function setEmergencyShutdown(bool _active) external onlyRole(SHUTDOWN_MANAGER) {
    /**
    @notice
        Activates or deactivates Vault mode where all Strategies go into full
        withdrawal.

        During Emergency Shutdown:
        1. No Users may deposit into the Vault (but may withdraw as usual.)
        2. Governance may not add new Strategies.
        3. Each Strategy must pay back their debt as quickly as reasonable to
            minimally affect their position.
        4. Only Governance may undo Emergency Shutdown.

        See contract level note for further details.

        This may only be called by governance or the guardian.
    @param active
        If true, the Vault goes into Emergency Shutdown. If false, the Vault
        goes back into Normal Operation.
     */
    if (!_active && !hasRole(GOVERNANCE, msg.sender)) revert OnlyGovernanceCanUndoShutdown();
    emergencyShutdown = _active;
    emit EmergencyShutdown(_active);
  }

  function performanceFeeThreshold() public pure returns (uint256) {
    return MAX_BPS / 2;
  }
}
