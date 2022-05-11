import { task } from 'hardhat/config';

task('deploy-strategy', 'Deploys a strategy')
  .addParam('strategy', 'The name of the strategy smart contract, e.g. JointStrategy')
  .addParam('vault', 'The address of the vault the strategy will interact with')
  .addOptionalParam('lendingPool', 'The lending pool the strategy integrates with')
  .setAction(async ({ strategy: strategyName, vault, ...taskParams }: { strategy: string; vault: string; lendingPool?: string }, hh) => {
    const strategyFactory = await hh.ethers.getContractFactory(strategyName);
    const strategy = await strategyFactory.deploy(vault, ...Object.values(taskParams));

    console.log(`Strategy ${strategyName} deployed to ${strategy.address}.`);
  });
