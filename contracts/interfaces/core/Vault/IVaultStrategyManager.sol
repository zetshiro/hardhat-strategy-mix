// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.4 <0.9.0;

interface IVaultStrategyManager {
  error UnhealthyStrategy(address strategy, uint256 gain, uint256 loss, uint256 totalDebt);

  error InvalidReport(uint256 expectedGain, uint256 gain, uint256 expectedLoss, uint256 loss);

  error NoChangeInDebt();

  error StrategyPerformanceFeeExceedThreshold();

  error InvalidWantToken();

  error InvalidVault();

  error LessThanMinDebt();

  error SameDebt();

  error NothingToWithdraw();

  // TODO (Yao): this can be a common error shared across contracts
  error ZeroAddress();

  // TODO (Yao): this can be a common error shared across strategy contracts
  error StrategyShutdown();

  event DebtUpdated(address strategy, uint256 oldDebt, uint256 newDebt);

  event StrategyAdded(
    address indexed strategy,
    uint256 performanceFee // Strategist's fee (basis points);
  );

  event StrategyMigrated(
    address indexed oldVersion, // Old version of the strategy to be migrated
    address indexed newVersion // New version of the strategy
  );

  event StrategyRevoked(
    address indexed strategy // Address of the strategy that is revoked
  );

  // TODO General: TWAP Oracle Module
  event StrategyReported(
    address indexed strategy,
    uint256 gain,
    uint256 loss,
    uint256 totalGain,
    uint256 totalLoss,
    uint256 totalDebt,
    uint256 totalFees
  );

  // event UpdateManagementFee(uint256 managementFee); //New active management fee

  function updateStrategyPerformanceFee(address _strategy, uint256 _performanceFee) external;

  function addStrategy(
    address _strategy,
    uint256 _managementFee,
    uint256 _performanceFee
  ) external;

  function migrateStrategy(address _oldVersion, address _newVersion) external;

  function revokeStrategy() external;

  function revokeStrategy(address _strategy) external;

  function updateDebt(address _strategy) external returns (uint256 _newDebt);

  function processStrategyReport(address _strategy) external returns (uint256 _profit, uint256 _loss);

  function processStrategyReportForced(
    address _strategy,
    uint256 _expectedGain,
    uint256 _expectedLoss
  ) external;
}
