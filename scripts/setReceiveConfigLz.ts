import { ethers, AbiCoder } from 'ethers';
import hre from 'hardhat';

const oappAddress = '0xe6388F7c0f7ad74f5F82693EfB46C021EaE976e0'; 
const receiveLibAddress = '0xc70AB6f32772f59fBfc23889Caf4Ba3376C84bAf';
const YOUR_ENDPOINT_CONTRACT_ADDRESS = '0x1a44076050125825900e736c501f859c50fE728c';

const remoteEid = 30110;
const ulnConfig = {
    confirmations: 2,
    requiredDVNCount: 1,
    optionalDVNCount: 0,
    optionalDVNThreshold: 0,
    requiredDVNs: ['0x9e059a54699a285714207b43b055483e78faac25'],
    optionalDVNs: [],
};


const endpointAbi = [
    'function setConfig(address oappAddress, address receiveLibAddress, tuple(uint32 eid, uint32 configType, bytes config)[] setConfigParams) external',
];
const configTypeUlnStruct = 'tuple(uint64 confirmations, uint8 requiredDVNCount, uint8 optionalDVNCount, uint8 optionalDVNThreshold, address[] requiredDVNs, address[] optionalDVNs)';


async function main() {
    const signer = await hre.ethers.provider.getSigner()
    const endpointContract = new ethers.Contract(YOUR_ENDPOINT_CONTRACT_ADDRESS, endpointAbi, signer);

    const abiCoder = AbiCoder.defaultAbiCoder();

    const encodedUlnConfig = abiCoder.encode([configTypeUlnStruct], [ulnConfig]);

    const setConfigParamUln = {
        eid: remoteEid,
        configType: 2, // ULN_CONFIG_TYPE
        config: encodedUlnConfig,
    };
    

    const tx = await endpointContract.setConfig(
        oappAddress,
        receiveLibAddress,
        [setConfigParamUln],
        // { gasLimit: 1000000}
    );

    console.log('Transaction sent:', tx.hash);
    const receipt = await tx.wait();
    console.log('Transaction confirmed:', receipt.transactionHash);
}

main().then(() => process.exit(0))