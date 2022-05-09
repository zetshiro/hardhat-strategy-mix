import { task } from 'hardhat/config';

task('deploy-strategy', 'Deploys a strategy')
  .addParam('strategy', 'The name of the strategy smart contract, e.g. JointStrategy')
  .addParam('vault', 'The address of the vault the strategy will interact with')
  .setAction(async (args: { strategy: string; vault: string }, hh) => {
    const strategyFactory = await hh.ethers.getContractFactory(args.strategy);
    const strategy = await strategyFactory.deploy(args.vault);

    console.log(`Strategy ${args.strategy} deployed to ${strategy.address}.`);
  });
