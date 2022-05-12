// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import {IAaveLendingPoolV2} from '../interfaces/IAaveLendingPoolV2.sol';
import {AaveLendingPoolV2Strategy} from '../AaveLendingPoolV2Strategy.sol';

contract AaveLendingPoolV2StrategyMock is AaveLendingPoolV2Strategy {
  constructor(address _vault, IAaveLendingPoolV2 _lendingPool) AaveLendingPoolV2Strategy(_vault, _lendingPool) {}

  function name() external pure override returns (string memory) {
    return string(abi.encodePacked('Strategy', 'AaveLendingPoolV2', 'Mock'));
  }

  function migrateInternal(address _newStrategy) external {
    _migrate(_newStrategy);
  }

  function freeFundsInternal(uint256 _amount) external {
    _freeFunds(_amount);
  }
}
