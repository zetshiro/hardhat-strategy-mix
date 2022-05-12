import { JsonRpcSigner } from '@ethersproject/providers';
import { AaveLendingPoolV2StrategyMock, AaveLendingPoolV2StrategyMock__factory, ERC20, Vault } from '@typechained';
import { evm, wallet } from '@utils';
import { given, then, when } from '@utils/bdd';
import { AAVE_CONTRACTS, TOKENS } from '@utils/constants';
import chai, { expect } from 'chai';
import { ethers } from 'hardhat';
import { loadVaultFixture } from 'test/fixtures/vault.fixture';
import { getNodeUrl } from 'utils/env';

import { solidity } from 'ethereum-waffle';
import { MockContract } from '@defi-wonderland/smock';
import { advanceToTimeAndBlock } from '@utils/evm';

chai.use(solidity);

const TEN_K_DAI = ethers.utils.parseEther('10000');

describe('AaveLendingPoolV2StrategyMock @skip-on-coverage', () => {
  let snapshotId: string;
  let lendingPoolStrategy: AaveLendingPoolV2StrategyMock;
  let newLendingPoolStrategy: AaveLendingPoolV2StrategyMock;

  let dai: ERC20;
  let daiWhale: JsonRpcSigner;
  let vault: MockContract<Vault>;

  before(async () => {
    await evm.reset({
      jsonRpcUrl: getNodeUrl('ethereum'),
    });

    const fixture = await loadVaultFixture({
      wantTokenAddress: TOKENS.DAI_ADDRESS,
      yieldTokenInput: {
        name: 'DAI Yield Token',
        symbol: 'yDAI',
      },
    });

    dai = fixture.wantToken;
    vault = fixture.vault;

    const lendingPoolStrategyFactory = await ethers.getContractFactory<AaveLendingPoolV2StrategyMock__factory>('AaveLendingPoolV2StrategyMock');
    lendingPoolStrategy = await lendingPoolStrategyFactory.deploy(vault.address, AAVE_CONTRACTS.V2.MAINNET_LENDING_POOL);

    const newLendingPoolStrategyFactory = await ethers.getContractFactory<AaveLendingPoolV2StrategyMock__factory>(
      'AaveLendingPoolV2StrategyMock'
    );
    newLendingPoolStrategy = await newLendingPoolStrategyFactory.deploy(vault.address, AAVE_CONTRACTS.V2.MAINNET_LENDING_POOL);

    daiWhale = await wallet.impersonate(TOKENS.DAI_WHALE_ADDRESS);
    snapshotId = await evm.snapshot.take();
  });

  beforeEach(async () => {
    await evm.snapshot.revert(snapshotId);
  });

  describe('harvest', () => {
    when('strategy has no deposits in the lending pool', () => {
      then('revert', async () => {
        await expect(lendingPoolStrategy.harvest()).to.be.revertedWith('InvalidAmount');
      });
    });

    when('strategy has deposits in the lending pool', () => {
      given(async () => {
        await dai.connect(daiWhale).transfer(lendingPoolStrategy.address, TEN_K_DAI);
        await lendingPoolStrategy.invest();
      });

      then('receive funds on harvest', async () => {
        expect(await lendingPoolStrategy.wantBalance()).to.be.equal(0);
        expect(await lendingPoolStrategy.aaveWantBalance()).to.be.closeTo(TEN_K_DAI, 100);

        await lendingPoolStrategy.harvest();

        expect(await lendingPoolStrategy.wantBalance()).to.be.gte(TEN_K_DAI);
        expect(await lendingPoolStrategy.aaveWantBalance()).to.be.equal(0);
      });
    });
  });

  // test migration
  describe('migrate', () => {
    when('strategy has no assets', () => {
      then('succeds', async () => {
        await lendingPoolStrategy.migrateInternal(newLendingPoolStrategy.address);

        expect(await newLendingPoolStrategy.wantBalance()).to.be.eq(0);
        expect(await newLendingPoolStrategy.aaveWantBalance()).to.be.eq(0);

        expect(await lendingPoolStrategy.wantBalance()).to.be.eq(0);
        expect(await lendingPoolStrategy.aaveWantBalance()).to.be.eq(0);
      });
    });

    when('strategy has assets', () => {
      // the strategy has both the underlying tokens and the aave tokens
      given(async () => {
        await dai.connect(daiWhale).transfer(lendingPoolStrategy.address, TEN_K_DAI);
        await lendingPoolStrategy.invest();
        await dai.connect(daiWhale).transfer(lendingPoolStrategy.address, TEN_K_DAI);
      });

      then('transfer all capital to the new strategy', async () => {
        const oldWantBalance = await lendingPoolStrategy.wantBalance();
        const oldAaveWantBalance = await lendingPoolStrategy.aaveWantBalance();

        expect(oldWantBalance).to.be.eq(TEN_K_DAI);
        expect(oldAaveWantBalance).to.be.gte(TEN_K_DAI);
        await lendingPoolStrategy.migrateInternal(newLendingPoolStrategy.address);

        expect(await lendingPoolStrategy.wantBalance()).to.be.eq(0);
        expect(await lendingPoolStrategy.aaveWantBalance()).to.be.eq(0);

        expect(await newLendingPoolStrategy.wantBalance()).to.be.eq(oldWantBalance);
        expect(await newLendingPoolStrategy.aaveWantBalance()).to.be.gte(oldAaveWantBalance);
      });
    });
  });

  describe('freeFunds', () => {
    when('strategy has no deposits in the lending pool', () => {
      then('revert', async () => {
        await expect(lendingPoolStrategy.freeFundsInternal(1)).to.be.revertedWith('InvalidAmount');
      });
    });

    when('strategy has deposits in the lending pool', () => {
      const amountToWithdraw = TEN_K_DAI.div(2);

      given(async () => {
        await dai.connect(daiWhale).transfer(lendingPoolStrategy.address, TEN_K_DAI);
        await lendingPoolStrategy.invest();
      });

      then('free funds from the lending pool', async () => {
        expect(await lendingPoolStrategy.wantBalance()).to.be.eq(0);
        expect(await lendingPoolStrategy.aaveWantBalance()).to.be.gte(TEN_K_DAI);

        await lendingPoolStrategy.freeFundsInternal(amountToWithdraw);
        expect(await lendingPoolStrategy.wantBalance()).to.be.eq(amountToWithdraw);
        expect(await lendingPoolStrategy.aaveWantBalance()).to.be.lt(TEN_K_DAI);
        expect(await lendingPoolStrategy.aaveWantBalance()).to.be.gte(amountToWithdraw);
      });
    });
  });

  // we expect emergencyFreeFunds to behave the same as freeFunds
  describe('emergencyFreeFunds', () => {
    when('strategy has no deposits in the lending pool', () => {
      then('revert', async () => {
        await expect(lendingPoolStrategy.freeFundsInternal(1)).to.be.revertedWith('InvalidAmount');
      });
    });

    when('strategy has deposits in the lending pool', () => {
      const amountToWithdraw = TEN_K_DAI.div(2);

      given(async () => {
        await dai.connect(daiWhale).transfer(lendingPoolStrategy.address, TEN_K_DAI);
        await lendingPoolStrategy.invest();
      });
      then('free funds from the lending pool', async () => {
        expect(await lendingPoolStrategy.wantBalance()).to.be.eq(0);
        expect(await lendingPoolStrategy.aaveWantBalance()).to.be.gte(TEN_K_DAI);

        await lendingPoolStrategy.freeFundsInternal(amountToWithdraw);
        expect(await lendingPoolStrategy.wantBalance()).to.be.eq(amountToWithdraw);
        expect(await lendingPoolStrategy.aaveWantBalance()).to.be.lt(TEN_K_DAI);
        expect(await lendingPoolStrategy.aaveWantBalance()).to.be.gte(amountToWithdraw);
      });
    });
  });

  describe('investTrigger', () => {
    // @todo fuzz the amount here
    when('strategy has no want tokens', () => {
      then('can not trigger invest', async () => {
        expect(await lendingPoolStrategy.investTrigger()).to.be.eq(false);
      });
    });

    when('strategy has want tokens', () => {
      given(async () => {
        await dai.connect(daiWhale).transfer(lendingPoolStrategy.address, TEN_K_DAI);
      });

      then('can trigger invest', async () => {
        expect(await lendingPoolStrategy.investTrigger()).to.be.eq(true);
      });
    });
  });

  describe('harvestTrigger', () => {
    const HOUR = 60 * 60 * 60;
    const DAY = 24 * HOUR;

    when('last vault report was less than 24 hours ago', () => {
      then('can not harvest trigger', async () => {
        expect(await lendingPoolStrategy.harvestTrigger()).to.be.eq(false);
      });
    });

    when('last vault report was more than 24 hours ago', () => {
      given(async () => {
        const now = Date.now() / 1000;
        await advanceToTimeAndBlock(now + DAY * 1.5);
      });

      then('can harvest trigger', async () => {
        expect(await lendingPoolStrategy.harvestTrigger()).to.be.eq(true);
      });
    });

    when('last vault report was exactly 24 hours ago', () => {
      given(async () => {
        const now = Date.now() / 1000;
        await advanceToTimeAndBlock(now + DAY);
      });

      then('can harvest trigger', async () => {
        expect(await lendingPoolStrategy.harvestTrigger()).to.be.eq(true);
      });
    });
  });
});
