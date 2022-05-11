// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.4 <0.9.0;

import {IAaveLendingPoolV2} from '../interfaces/IAaveLendingPoolV2.sol';
import {AaveLendingPoolV2Strategy} from '../AaveLendingPoolV2Strategy.sol';

contract AaveLendingPoolV2USDCStrategy is AaveLendingPoolV2Strategy {
  constructor(address _vault, IAaveLendingPoolV2 _pool) AaveLendingPoolV2Strategy(_vault, _pool) {}

  function name() external pure override returns (string memory) {
    return string(abi.encodePacked('Strategy', 'AaveLendingPoolV2', 'USDC'));
  }
}
