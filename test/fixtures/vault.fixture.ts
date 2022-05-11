import { MockContract, MockContractFactory, smock } from '@defi-wonderland/smock';
import { Vault, Vault__factory, YieldToken__factory, YieldToken, ERC20Mock__factory, ERC20Mock, ERC20__factory, ERC20 } from '@typechained';
import { ZERO_ADDRESS } from '@utils/wallet';
import { loadFixture, MockProvider } from 'ethereum-waffle';
import { Wallet } from 'ethers';
import { ethers } from 'hardhat';

interface VaultFixture {
  vault: MockContract<Vault>;
  wantToken: MockContract<ERC20Mock>;
  yieldToken: MockContract<YieldToken>;
}

interface VaultOverloadFixture {
  vault: MockContract<Vault>;
  wantToken: ERC20;
  yieldToken: MockContract<YieldToken>;
}

type VaultFixtureOverloadInput = {
  wantTokenAddress: string;
  yieldTokenInput: {
    name: string;
    symbol: string;
  };
};

type VaultFixtureWrapperInput = VaultFixtureOverloadInput | 'default';
type VaultFixtureReturnVaule<T extends VaultFixtureWrapperInput> = T extends VaultFixtureOverloadInput ? VaultOverloadFixture : VaultFixture;

export const vaultFixture = <T extends VaultFixtureWrapperInput>(input: T) => {
  return async (_wallets: Wallet[], _provider: MockProvider): Promise<VaultFixtureReturnVaule<T>> => {
    let signers = await ethers.getSigners();
    let signer = signers[0];

    let yieldTokenMockFactory: MockContractFactory<YieldToken__factory>;
    let yieldTokenMock: MockContract<YieldToken>;
    let tokenMockFactory: MockContractFactory<ERC20Mock__factory>;
    let wantToken: MockContract<ERC20Mock> | ERC20;
    let vaultMockFactory: MockContractFactory<Vault__factory>;
    let vaultMock: MockContract<Vault>;

    const params: VaultFixtureOverloadInput | null = input && typeof input === 'object' ? input : null;
    const erc20Factory = await ethers.getContractFactory<ERC20__factory>('ERC20');

    vaultMockFactory = await smock.mock<Vault__factory>('contracts/core/Vault/Vault.sol:Vault');
    vaultMock = await vaultMockFactory.deploy();

    tokenMockFactory = await smock.mock<ERC20Mock__factory>('contracts/mocks/ERC20Mock.sol:ERC20Mock');
    wantToken = params ? erc20Factory.attach(params.wantTokenAddress) : await tokenMockFactory.deploy('mock', 'MOCK', signer.address, 0);

    yieldTokenMockFactory = await smock.mock<YieldToken__factory>('contracts/core/YieldToken.sol:YieldToken');
    yieldTokenMock = await yieldTokenMockFactory.deploy();

    await vaultMock.initialize(
      yieldTokenMock.address,
      wantToken.address,
      signer.address,
      signer.address,
      '',
      '',
      signer.address,
      signer.address,
      ZERO_ADDRESS
    );

    await yieldTokenMock.initialize(
      params?.yieldTokenInput?.name ?? '',
      params?.yieldTokenInput?.symbol ?? '',
      wantToken.address,
      vaultMock.address
    );

    return { vault: vaultMock, wantToken, yieldToken: yieldTokenMock } as VaultFixtureReturnVaule<T>;
  };
};

export const loadVaultFixture = <T extends VaultFixtureWrapperInput>(input: T) => loadFixture(vaultFixture(input));
