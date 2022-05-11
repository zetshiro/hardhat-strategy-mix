import { MockContract, MockContractFactory, smock } from '@defi-wonderland/smock';
import { Vault, Vault__factory, YieldToken__factory, YieldToken, ERC20Mock__factory, ERC20Mock } from '@typechained';
import { ZERO_ADDRESS } from '@utils/wallet';
import { loadFixture, MockProvider } from 'ethereum-waffle';
import { Wallet } from 'ethers';
import { ethers } from 'hardhat';

export interface VaultFixture {
  vault: MockContract<Vault>;
  tokenMock: MockContract<ERC20Mock>;
  yieldToken: MockContract<YieldToken>;
}

export async function vaultFixture(_wallets: Wallet[], provider: MockProvider): Promise<VaultFixture> {
  let signers = await ethers.getSigners();
  let signer = signers[0];

  let yieldTokenMockFactory: MockContractFactory<YieldToken__factory>;
  let yieldTokenMock: MockContract<YieldToken>;
  let tokenMockFactory: MockContractFactory<ERC20Mock__factory>;
  let tokenMock: MockContract<ERC20Mock>;
  let vaultMockFactory: MockContractFactory<Vault__factory>;
  let vaultMock: MockContract<Vault>;

  vaultMockFactory = await smock.mock<Vault__factory>('contracts/core/Vault/Vault.sol:Vault');
  vaultMock = await vaultMockFactory.deploy();

  tokenMockFactory = await smock.mock<ERC20Mock__factory>('contracts/mocks/ERC20Mock.sol:ERC20Mock');
  tokenMock = await tokenMockFactory.deploy('mock', 'MOCK', signer.address, 0);

  yieldTokenMockFactory = await smock.mock<YieldToken__factory>('contracts/core/YieldToken.sol:YieldToken');
  yieldTokenMock = await yieldTokenMockFactory.deploy();

  await vaultMock.initialize(
    yieldTokenMock.address,
    tokenMock.address,
    signer.address,
    signer.address,
    '',
    '',
    signer.address,
    signer.address,
    ZERO_ADDRESS
  );

  await yieldTokenMock.initialize('', '', tokenMock.address, vaultMock.address);

  return { vault: vaultMock, tokenMock: tokenMock, yieldToken: yieldTokenMock };
}

export const loadVaultFixture = () => loadFixture(vaultFixture);
