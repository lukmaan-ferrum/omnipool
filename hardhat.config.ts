import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import dotenv from 'dotenv'
dotenv.config()

const config: HardhatUserConfig = {
	solidity: {
		compilers: [
			{
				version: "0.8.24",
				settings: {
					optimizer: {
						enabled: true,
						runs: 50,
					},
				},
			},
		],
	},
	networks: {
		hardhat: {
			forking: {
				url: process.env.ARBITRUM_RPC_URL!
			}
		},
		localhost: {
			accounts: [process.env.DEPLOYER_KEY!]
		},
		bsc: {
			url: process.env.BSC_RPC_URL,
			accounts: [process.env.DEPLOYER_KEY!]
		},
		arbitrumOne: {
			url: process.env.ARBITRUM_RPC_URL,
			accounts: [process.env.DEPLOYER_KEY!]
		},
		base: {
			url: process.env.BASE_RPC_URL,
			accounts: [process.env.DEPLOYER_KEY!]
		},
		polygon: {
			url: process.env.POLYGON_RPC_URL,
			accounts: [process.env.DEPLOYER_KEY!]
		},
		optimism: {
			url: process.env.OPTIMISM_RPC_URL,
			accounts: [process.env.DEPLOYER_KEY!]
		},
	},
	etherscan: {
		apiKey: {
			arbitrumOne: process.env.ARBISCAN_API_KEY!,
			base: process.env.BASESCAN_API_KEY!,
			optimisticEthereum: process.env.OPTIMISMSCAN_API_KEY!,
			polygon: process.env.POLYGONSCAN_API_KEY!,
		}
	},
	ignition: {
		strategyConfig: {
			create2: {
				salt: "0x1000000000000000000000000000000000000000000000000000000000000002"
			},
		},
	},
};

export default config;
