import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import dotenv from 'dotenv'
dotenv.config()

const config: HardhatUserConfig = {
	solidity: "0.8.24",
	networks: {
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
		}
	},
	etherscan: {
		apiKey: {
			arbitrumOne: process.env.ARBISCAN_API_KEY!,
			base: process.env.BASESCAN_API_KEY!,
			bsc: process.env.BSCSCAN_API_KEY!,
		}
	},
	ignition: {
		strategyConfig: {
			create2: {
				salt: "0x0000000000000000000000000000000000000000000000000000000000000001"
			},
		},
	},
};

export default config;
