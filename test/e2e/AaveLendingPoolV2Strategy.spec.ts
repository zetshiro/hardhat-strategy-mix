import { AaveLendingPoolV2USDCStrategy, AaveLendingPoolV2USDCStrategy__factory } from '@typechained';
import { evm } from '@utils';
import { when } from '@utils/bdd';
import { ethers } from 'hardhat';

describe('AaveLendingPoolV2Strategy @skip-on-coverage', () => {
  let snapshotId: string;
  let lendingPoolStrategy: AaveLendingPoolV2USDCStrategy;

  before(async () => {
    snapshotId = await evm.snapshot.take();
    const lendingPoolStrategyFactory = await ethers.getContractFactory<AaveLendingPoolV2USDCStrategy__factory>('AaveLendingPoolV2USDCStrategy');
    lendingPoolStrategy = await lendingPoolStrategyFactory.deploy('', '');
  });

  beforeEach(async () => {
    await evm.snapshot.revert(snapshotId);
  });

  // test profitable harvest
  describe('harvest', () => {
    when('strategy has no deposits in the lending pool', () => {});

    when('strategy has deposits in the lending pool', () => {});
  });

  // test migration
  describe('migrate', () => {
    when('strategy has no assets', () => {});

    when('strategy has assets', () => {});
  });

  // test free funds
  describe('freeFunds', () => {
    when('strategy has no deposits in the lending pool', () => {});
    when('strategy has no deposits in the lending pool', () => {});
  });

  // we expect emergencyFreeFunds to behave the same as freeFunds
  describe('emergencyFreeFunds', () => {});

  // test the trigger methods
  describe('investTrigger', () => {
    when('strategy has no want tokens', () => {});

    when('strategy has want tokens', () => {});
  });

  describe('harvestTrigger', () => {
    when('last vault report was less than 24 hours ago', () => {});
    when('last vault report was more than 24 hours ago', () => {});
    when('last vault report was exactly 24 hours ago', () => {});
  });
});
