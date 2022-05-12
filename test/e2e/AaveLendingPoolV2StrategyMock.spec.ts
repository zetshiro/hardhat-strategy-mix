import { JsonRpcSigner } from '@ethersproject/providers';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { AaveLendingPoolV2StrategyMock, AaveLendingPoolV2StrategyMock__factory, ERC20, Vault } from '@typechained';
import { evm, wallet } from '@utils';
import { given, then, when } from '@utils/bdd';
import { TOKENS } from '@utils/constants';
import chai, { expect } from 'chai';
import { ethers } from 'hardhat';
import { loadVaultFixture } from 'test/fixtures/vault.fixture';
import { getNodeUrl } from 'utils/env';

import { solidity } from 'ethereum-waffle';
import { MockContract } from '@defi-wonderland/smock';

chai.use(solidity);

const AAVE_LENDING_PPOL_ADDRESS = '0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9';

const TEN_K_DAI = ethers.utils.parseEther('10000');

describe('AaveLendingPoolV2StrategyMock @skip-on-coverage', () => {
  let snapshotId: string;
  let lendingPoolStrategy: AaveLendingPoolV2StrategyMock;
  let newLendingPoolStrategy: AaveLendingPoolV2StrategyMock;

  let dai: ERC20;
  let signer: SignerWithAddress;
  let daiWhale: JsonRpcSigner;
  let vault: MockContract<Vault>;

  before(async () => {
    [signer] = await ethers.getSigners();

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
    lendingPoolStrategy = await lendingPoolStrategyFactory.deploy(vault.address, AAVE_LENDING_PPOL_ADDRESS);

    const newLendingPoolStrategyFactory = await ethers.getContractFactory<AaveLendingPoolV2StrategyMock__factory>(
      'AaveLendingPoolV2StrategyMock'
    );
    newLendingPoolStrategy = await newLendingPoolStrategyFactory.deploy(vault.address, AAVE_LENDING_PPOL_ADDRESS);

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
