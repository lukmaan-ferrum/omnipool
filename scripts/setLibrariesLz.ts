import { ethers } from "hardhat";
import hre from "hardhat";

const endpointAbi = [
    'function setSendLibrary(address oapp, uint32 eid, address sendLib) external',
    'function setReceiveLibrary(address oapp, uint32 eid, address receiveLib, uint256 _gracePeriod) external',
];

async function setLibraries() {

    // Replace with your actual values
    const YOUR_OAPP_ADDRESS = '0x3ca437941Db4b4797046bc7B814fD9C80293bC6a';
    const YOUR_SEND_LIB_ADDRESS = '0xB5320B0B3a13cC860893E2Bd79FCd7e13484Dda2';
    const YOUR_RECEIVE_LIB_ADDRESS = '0xc70AB6f32772f59fBfc23889Caf4Ba3376C84bAf';
    const YOUR_ENDPOINT_CONTRACT_ADDRESS = '0x1a44076050125825900e736c501f859c50fE728c';
    const remoteEid = 30111;

    const signer = await hre.ethers.provider.getSigner()
    const endpointContract = new ethers.Contract(YOUR_ENDPOINT_CONTRACT_ADDRESS, endpointAbi, signer);

    // Set the send library
    const sendTx = await endpointContract.setSendLibrary(
        YOUR_OAPP_ADDRESS,
        remoteEid,
        YOUR_SEND_LIB_ADDRESS,
    );

    console.log('Send library transaction sent:', sendTx.hash);
    await sendTx.wait();
    console.log('Send library set successfully.');

    // Set the receive library
    const receiveTx = await endpointContract.setReceiveLibrary(
        YOUR_OAPP_ADDRESS,
        remoteEid,
        YOUR_RECEIVE_LIB_ADDRESS,
        0n,
    );
    console.log('Receive library transaction sent:', receiveTx.hash);
    await receiveTx.wait();
    console.log('Receive library set successfully.');
}

setLibraries();