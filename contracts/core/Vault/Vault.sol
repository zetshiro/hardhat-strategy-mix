// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {SafeERC20} from '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';
import '@openzeppelin/contracts/utils/math/Math.sol';

import {VaultAccessControl} from './VaultAccessControl.sol';
import {VaultParameters} from './VaultParameters.sol';
import {IYieldToken} from '../../interfaces/core/IYieldToken.sol';
import {IERC20Metadata} from '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';

import {IVault} from '../../interfaces/core/Vault/IVault.sol';

/**
    *  @title Yearn Token Vault
    * @author yearn.finance
    * @notice
    Yearn Token Vault. Holds an underlying token, and allows users to interact
    with the Yearn ecosystem through Strategies connected to the Vault.
    Vaults are not limited to a single Strategy, they can have as many Strategies
    as can be designed (however the withdrawal queue is capped at 20.)

    Deposited funds are moved into the most impactful strategy that has not
    already reached its limit for assets under management, regardless of which
    Strategy a user's funds end up in, they receive their portion of yields
    generated across all Strategies.

    When a user withdraws, if there are no funds sitting undeployed in the
    Vault, the Vault withdraws funds from Strategies in the order of least
    impact. (Funds are taken from the Strategy that will disturb everyone's
    gains the least, then the next least, etc.) In order to achieve this, the
    withdrawal queue's order must be properly set and managed by the community
    (through governance).

    Vault Strategies are parameterized to pursue the highest risk-adjusted yield.

    There is an "Emergency Shutdown" mode. When the Vault is put into emergency
    shutdown, assets will be recalled from the Strategies as quickly as is
    practical (given on-chain conditions), minimizing loss. Deposits are
    halted, new Strategies may not be added, and each Strategy exits with the
    minimum possible damage to position, while opening up deposits to be
    withdrawn by users. There are no restrictions on withdrawals above what is
    expected under Normal Operation.

    For further details, please refer to the specification:
    https://github.com/iearn-finance/yearn-vaults/blob/main/SPECIFICATION.md
 */
contract Vault is IVault, VaultParameters {
  using SafeERC20 for IERC20;

  // end of Events

  // Storage

  // `nonces` track `permit` approvals with signature.

  // end of Storage
  /***
    @notice
        Initializes the Vault, this is called only once, when the contract is
        deployed.
        The performance fee is set to 10% of yield, per Strategy.
        The management fee is set to 2%, per year.
        The initial deposit limit is set to 0 (deposits disabled); it must be
        updated after initialization.
    @dev
        If `nameOverride` is not specified, the name will be 'yearn'
        combined with the name of `token`.

        If `symbolOverride` is not specified, the symbol will be 'yv'
        combined with the symbol of `token`.

        The token used by the vault should not change balances outside transfers and
        it must transfer the exact amount requested. Fee on transfer and rebasing are not supported.
    @param yieldToken, The yield token that this Vault will use, it represent ownership in the vault.
    @param token The token that may be deposited into this Vault.
    @param governance The address authorized for governance interactions.
    @param rewards The address to distribute rewards to.
    @param management The address of the vault manager.
    @param nameOverride Specify a custom Vault name. Leave empty for default choice.
    @param symbolOverride Specify a custom Vault symbol name. Leave empty for default choice.
    @param guardian The address authorized for guardian interactions. Defaults to caller.
    **/
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
  ) external initializer {
    yieldToken = _yieldToken;
    token = _token;
    bytes32 emptyString = keccak256(abi.encodePacked(''));
    string memory tokenSymbol = IERC20Metadata(_token).symbol();

    if (keccak256(abi.encodePacked(_nameOverride)) == emptyString) {
      // Maybe check length instead.
      name = string(abi.encodePacked(tokenSymbol, ' yVault'));
    } else {
      name = _nameOverride;
    }
    if (keccak256(abi.encodePacked(_symbolOverride)) == emptyString) {
      symbol = string(abi.encodePacked('yv', tokenSymbol));
    } else {
      symbol = _symbolOverride;
    }

    rewardsRecipient = _rewardsRecipient;

    performanceFee = 1000; // 10% of yield (per Strategy)

    // managementFee = 200; // 2% per year

    healthCheck = _healthCheck;

    lastReport = block.timestamp;
    __VaultAccessControl_init(_governance, _guardian, _management);

    emit VaultInitialized(
      _yieldToken,
      _token,
      _governance,
      _rewardsRecipient,
      _nameOverride,
      _symbolOverride,
      _guardian,
      _management,
      _healthCheck,
      performanceFee,
      lastReport
    );
  }

  function sweep(address _token) external onlyRole(GOVERNANCE) returns (uint256 _amount) {
    /**
    @notice
        Removes tokens from this Vault that are not the type of token managed
        by this Vault. This may be used if the wrong kind of token was sent to
        this vault.

        If the token being swept is the token being managed by this vault, only
        tokens in excess of the amount managed by this vault will be swept.

        Sweep will always sweep the entire balance that is in excess.

        Tokens will be sent to `governance`.

        This may only be called by governance.
    @param _token The token to transfer out of this vault.
    @return _amount The amount of tokens transferred out of the vault.
    */
    if (_token == token) {
      _amount = IERC20(_token).balanceOf(address(this)) - totalIdle;
      if (_amount == 0) revert NoDust();
    } else {
      _amount = IERC20(_token).balanceOf(address(this));
    }
    IERC20(_token).safeTransfer(msg.sender, _amount);
    emit Sweep(_token, _amount);
  }
}
