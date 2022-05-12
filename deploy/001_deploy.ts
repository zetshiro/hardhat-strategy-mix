import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { DeployFunction } from 'hardhat-deploy/types';
import { getChainId, shouldVerifyContract } from '../utils/deploy';
import { AAVE_CONTRACTS } from '@utils/constants';

export const LENDING_POOL_STRATEGY_ARGS: { [chainId: string]: unknown[] } = {
  '1': [process.env.AAVE_LENDING_POOL_V2_STRATEGY_VAULT, AAVE_CONTRACTS.V2.MAINNET_LENDING_POOL],
};

const deployFunction: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployer } = await hre.getNamedAccounts();

  const chainId = await getChainId(hre);

  const deploy = await hre.deployments.deploy('AaveLendingPoolV2DAIStrategy', {
    contract: 'contracts/examples/AaveLendingPoolV2DAIStrategy.sol:AaveLendingPoolV2DAIStrategy',
    from: deployer,
    args: [...LENDING_POOL_STRATEGY_ARGS[chainId]],
    log: true,
  });

  if (await shouldVerifyContract(deploy)) {
    await hre.run('verify:verify', {
      address: deploy.address,
      constructorArguments: [...LENDING_POOL_STRATEGY_ARGS[chainId]],
    });
  }
};
deployFunction.dependencies = [];
deployFunction.tags = ['AaveLendingPoolV2DAIStrategy'];
export default deployFunction;
