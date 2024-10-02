import { ethers, AbiCoder } from 'ethers';
import hre from 'hardhat';

const oappAddress = '0x3ca437941Db4b4797046bc7B814fD9C80293bC6a'; 
const sendLibAddress = '0xB5320B0B3a13cC860893E2Bd79FCd7e13484Dda2';
const YOUR_ENDPOINT_CONTRACT_ADDRESS = '0x1a44076050125825900e736c501f859c50fE728c';
const executorAddress = "0x2CCA08ae69E0C44b18a57Ab2A87644234dAebaE4"

const remoteEid = 30111;
const ulnConfig = {
    confirmations: 2,
    requiredDVNCount: 1,
    optionalDVNCount: 0,
    optionalDVNThreshold: 0,
    requiredDVNs: ['0x9e059a54699a285714207b43b055483e78faac25'],
    optionalDVNs: [],
};

const executorConfig = {
    maxMessageSize: 10000000,
    executorAddress
};

const endpointAbi = [
    'function setConfig(address oappAddress, address sendLibAddress, tuple(uint32 eid, uint32 configType, bytes config)[] setConfigParams) external',
];
const configTypeUlnStruct = 'tuple(uint64 confirmations, uint8 requiredDVNCount, uint8 optionalDVNCount, uint8 optionalDVNThreshold, address[] requiredDVNs, address[] optionalDVNs)';
const configTypeExecutorStruct = 'tuple(uint32 maxMessageSize, address executorAddress)';


async function main() {
    const signer = await hre.ethers.provider.getSigner()
    const endpointContract = new ethers.Contract(YOUR_ENDPOINT_CONTRACT_ADDRESS, endpointAbi, signer);

    const abiCoder = AbiCoder.defaultAbiCoder();

    const encodedUlnConfig = abiCoder.encode([configTypeUlnStruct], [ulnConfig]);
    const encodedExecutorConfig = abiCoder.encode([configTypeExecutorStruct], [executorConfig]);

    const setConfigParamUln = {
        eid: remoteEid,
        configType: 2, // ULN_CONFIG_TYPE
        config: encodedUlnConfig,
    };
    const setConfigParamExecutor = {
        eid: remoteEid,
        configType: 1, // EXECUTOR_CONFIG_TYPE
        config: encodedExecutorConfig,
    };

    const tx = await endpointContract.setConfig(
        oappAddress,
        sendLibAddress,
        [setConfigParamUln, setConfigParamExecutor], // Array of SetConfigParam structs
    );

    console.log('Transaction sent:', tx.hash);
    const receipt = await tx.wait();
    console.log('Transaction confirmed:', receipt.transactionHash);

}

main().then(() => process.exit(0))