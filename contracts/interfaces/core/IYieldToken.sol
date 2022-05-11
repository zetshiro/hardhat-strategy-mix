// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.4 <0.9.0;

import '@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol';

interface IYieldToken is IERC20Upgradeable {
  error NoVault();

  function initialize(
    string memory _name,
    string memory _symbol,
    address _underlyingToken,
    address _vault
  ) external;

  function MASTER_ADMIN() external view returns (bytes32 _masterAdmin);

  function VAULT_MIGRATOR() external view returns (bytes32 _vaultMigrator);

  function VAULT_MIGRATOR_ADMIN() external view returns (bytes32 _vaultMigratorAdmin);

  function vault() external view returns (address _vault);

  function underlyingToken() external view returns (address _underlyingToken);

  function mint(address _account, uint256 _amount) external;

  function burn(address _from, uint256 _amount) external;

  function transferOwnership(address _newVault) external;

  function migrateVault(address _newVault) external;
}
