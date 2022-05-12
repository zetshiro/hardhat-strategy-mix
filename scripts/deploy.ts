import { AaveLendingPoolV2DAIStrategy__factory } from '@typechained';
import { AAVE_CONTRACTS } from '@utils/constants';
import { run, ethers } from 'hardhat';

async function main() {
  if (!process.env.AAVE_LENDING_POOL_V2_STRATEGY_VAULT) {
    throw new Error('AAVE_LENDING_POOL_V2_STRATEGY_VAULT is not defined in .env');
  }

  run('compile');
  const aaveLendingPoolV2DAIStrategy = await ethers.getContractFactory<AaveLendingPoolV2DAIStrategy__factory>('AaveLendingPoolV2DAIStrategy');

  const lendingPool = await aaveLendingPoolV2DAIStrategy.deploy(
    process.env.AAVE_LENDING_POOL_V2_STRATEGY_VAULT,
    // @todo change the lending pool address based on the network
    AAVE_CONTRACTS.V2.MAINNET_LENDING_POOL
  );

  console.log('AaveLendingPoolV2DAIStrategy deployed to:', lendingPool.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
