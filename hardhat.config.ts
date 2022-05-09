import 'dotenv/config';
import '@nomiclabs/hardhat-waffle';
import '@nomiclabs/hardhat-ethers';
import '@nomiclabs/hardhat-etherscan';
import '@typechain/hardhat';
import '@typechain/hardhat/dist/type-extensions';
import { removeConsoleLog } from 'hardhat-preprocessor';
import 'hardhat-gas-reporter';
import 'hardhat-deploy';
import 'solidity-coverage';
import { HardhatUserConfig, MultiSolcUserConfig, NetworksUserConfig } from 'hardhat/types';
import { task } from 'hardhat/config';
import * as env from './utils/env';
import 'tsconfig-paths/register';
import { ethers } from 'hardhat';

task('deploy-strategy', 'Deploys a strategy')
  .addParam('strategy', 'The name of the strategy smart contract, e.g. JointStrategy')
  .addParam('vault', 'The address of the vault the strategy will interact with')
  .setAction(async (args: { strategy: string; vault: string }, _hh) => {
    const strategyFactory = await ethers.getContractFactory(args.strategy);
    const strategy = await strategyFactory.deploy(args.vault);

    console.log(`Strategy ${args.strategy} deployed to ${strategy.address}.`);
  });

const networks: NetworksUserConfig =
  env.isHardhatCompile() || env.isHardhatClean() || env.isTesting()
    ? {}
    : {
        hardhat: {
          forking: {
            enabled: process.env.FORK ? true : false,
            url: env.getNodeUrl('ethereum'),
          },
        },
        localhost: {
          url: env.getNodeUrl('localhost'),
          accounts: env.getAccounts('localhost'),
        },
        rinkeby: {
          url: env.getNodeUrl('rinkeby'),
          accounts: env.getAccounts('rinkeby'),
        },
        ropsten: {
          url: env.getNodeUrl('ropsten'),
          accounts: env.getAccounts('ropsten'),
        },
        kovan: {
          url: env.getNodeUrl('kovan'),
          accounts: env.getAccounts('kovan'),
        },
        ethereum: {
          url: env.getNodeUrl('ethereum'),
          accounts: env.getAccounts('ethereum'),
        },
      };

const config: HardhatUserConfig = {
  defaultNetwork: 'hardhat',
  namedAccounts: {
    deployer: {
      default: 0,
    },
  },
  mocha: {
    timeout: process.env.MOCHA_TIMEOUT || 300000,
  },
  networks,
  solidity: {
    compilers: [
      {
        version: '0.8.9',
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          },
        },
      },
    ],
  },
  gasReporter: {
    currency: process.env.COINMARKETCAP_DEFAULT_CURRENCY || 'USD',
    coinmarketcap: process.env.COINMARKETCAP_API_KEY,
    enabled: process.env.REPORT_GAS ? true : false,
    showMethodSig: true,
    onlyCalledMethods: false,
  },
  preprocess: {
    eachLine: removeConsoleLog((hre) => hre.network.name !== 'hardhat'),
  },
  etherscan: {
    apiKey: env.getEtherscanAPIKeys(['ethereum']),
  },
  typechain: {
    outDir: 'typechained',
    target: 'ethers-v5',
  },
};

if (process.env.TEST) {
  (config.solidity as MultiSolcUserConfig).compilers = (config.solidity as MultiSolcUserConfig).compilers.map((compiler) => {
    return {
      ...compiler,
      outputSelection: {
        '*': {
          '*': ['storageLayout'],
        },
      },
    };
  });
}

export default config;
