// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.4 <0.9.0;

interface IVaultParameters {
  struct StrategyParams {
    uint256 managementFee; // Management fee
    uint256 performanceFee; // Strategist's fee (basis points)
    uint256 activation; // Activation block.timestamp
    uint256 lastReport; // block.timestamp of the last time a report occured
    uint256 totalDebt; // Total outstanding debt that Strategy has
    uint256 totalGain; // Total returns that Strategy has realized for Vault
    uint256 totalLoss; // Total losses that Strategy has realized for Vault
    // TODO Add withdrawable flag bool withdrawable;
  }

  event UpdateDepositLimit(uint256 depositLimit); // New active deposit limit

  event UpdatePerformanceFee(uint256 performanceFee); //New active performance fee

  event EmergencyShutdown(bool active); //New emergency shutdown state (if false, normal operation enabled);

  event UpdateHealthCheck(address healthcheck);

  event StrategyUpdatePerformanceFee(
    address indexed strategy, // Address of the strategy for the performance fee adjustment
    uint256 performanceFee // The new performance fee for the strategy
  );

  error ZeroAmount();

  error PerformanceFeeExceedThreshold();

  function strategies(address _strategy) external view returns (StrategyParams memory);

  function setDebtAllocator(address _debtAllocator) external;

  function setHealthCheck(address _healthCheck) external;

  function depositLimit() external view returns (uint256 _depositLimit);

  function totalDebt() external view returns (uint256 _totalDebt);

  function totalIdle() external view returns (uint256 _totalIdle);

  function lastReport() external view returns (uint256 _lastReport);

  function activation() external view returns (uint256 _activation);

  function lockedProfit() external view returns (uint256 _lockedProfit);

  function previousHarvestTimeDelta() external view returns (uint256 _previousHarvestTimeDelta);

  function yieldToken() external view returns (address _yieldToken);

  function token() external view returns (address _token);

  function name() external view returns (string calldata _name);

  function symbol() external view returns (string calldata _symbol);

  function performanceFee() external view returns (uint256 _performanceFee);

  function emergencyShutdown() external view returns (bool _emergencyShutdown);

  function apiVersion() external pure returns (string memory);

  function setPerformanceFee(uint256 _fee) external;

  function setDepositLimit(uint256 _limit) external;

  function setEmergencyShutdown(bool _active) external;

  function performanceFeeThreshold() external view returns (uint256);

  function debtAllocator() external view returns (address _debtAllocator);

  function healthCheck() external view returns (address _healthCheck);
}
