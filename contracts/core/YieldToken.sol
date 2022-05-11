// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.4 <0.9.0;

import '@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol';
import '../interfaces/core/IYieldToken.sol';

contract YieldToken is IYieldToken, ERC20Upgradeable, AccessControlUpgradeable {
  // TODO use PERMIT ERC20: @openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol
  /**
  mapping(address => uint256) public nonces;
  bytes32 public DOMAIN_SEPARATOR;
  bytes32 public constant DOMAIN_TYPE_HASH = keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)');
  bytes32 public constant PERMIT_TYPE_HASH = keccak256('Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)');
 */

  bytes32 public constant MASTER_ADMIN = keccak256('MASTER_ADMIN');

  bytes32 public constant VAULT_MIGRATOR = keccak256('VAULT_MIGRATOR');
  bytes32 public constant VAULT_MIGRATOR_ADMIN = keccak256('VAULT_MIGRATOR_ADMIN');

  address public vault;
  address public underlyingToken;

  function initialize(
    string memory _name,
    string memory _symbol,
    address _underlyingToken,
    address _vault
  ) external initializer {
    __ERC20_init(_name, _symbol);
    underlyingToken = _underlyingToken;
    _setRoleAdmin(MASTER_ADMIN, MASTER_ADMIN);
    _setRoleAdmin(VAULT_MIGRATOR_ADMIN, MASTER_ADMIN);
    _setRoleAdmin(VAULT_MIGRATOR, VAULT_MIGRATOR_ADMIN);

    _setupRole(MASTER_ADMIN, msg.sender);
    _setupRole(VAULT_MIGRATOR, msg.sender);
    _setupRole(VAULT_MIGRATOR_ADMIN, msg.sender);
    vault = _vault;
  }

  /**
    - 00z leading deploy
    - gas optimized erc20 implementation
    - minter role for Vault
    - view function for get Vault
    - transfer ownership to new vault
 */

  function mint(address _to, uint256 _amount) external {
    if (msg.sender != vault) revert NoVault();
    _mint(_to, _amount);
  }

  function burn(address _from, uint256 _amount) external {
    if (msg.sender != vault) revert NoVault();
    _burn(_from, _amount);
  }

  function transferOwnership(address _newVault) external {
    if (msg.sender != vault) revert NoVault();
    vault = _newVault;
  }

  // safeguard functions

  // used in case we brick the vault, and it cannot be migrated.
  function migrateVault(address _newVault) external onlyRole(VAULT_MIGRATOR) {
    // TODO: check if old vault is already in migrate state
    vault = _newVault;
  }

  // TODO collect dust
}
