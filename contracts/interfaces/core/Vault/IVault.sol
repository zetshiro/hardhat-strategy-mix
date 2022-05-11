// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.4 <0.9.0;

import {IVaultParameters} from './IVaultParameters.sol';

interface IVault {
  error NoDust();

  event Sweep(address indexed token, uint256 amount);

  event VaultInitialized(
    address yieldToken,
    address token,
    address governance,
    address rewardsRecipient,
    string nameOverride,
    string symbolOverride,
    address guardian,
    address management,
    address healthCheck,
    uint256 performanceFee,
    uint256 lastReport
  );

  function initialize(
    address _yieldToken,
    address _token,
    address _governance,
    address _rewardsRecipient,
    string calldata _nameOverride,
    string calldata _symbolOverride,
    address _guardian,
    address _management,
    address _healthCheck
  ) external;

  function sweep(address _token) external returns (uint256 _amount);
}
