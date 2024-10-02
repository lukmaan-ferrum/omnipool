import hre from "hardhat"
import {BigNumberish, BytesLike} from 'ethers';
import {Options} from '@layerzerolabs/lz-v2-utilities';
import {addressToBytes32} from '@layerzerolabs/lz-v2-utilities';



const main = async () => {
    const signer = await hre.ethers.provider.getSigner()

    const oftAddr = "0x3ca437941Db4b4797046bc7B814fD9C80293bC6a"
    const oft = await hre.ethers.getContractAt("XOFT", oftAddr, signer) as any

    const amount = 3000000000000000000n

    const params = {
        dstEid: 30111,
        to: addressToBytes32(signer.address),
        amountLD: amount,
        minAmountLD: amount,
        extraOptions: Options.newOptions().addExecutorLzReceiveOption(65000, 0).toBytes(),
        composeMsg: "0x",
        oftCmd: "0x"
    }

    const feeQuote = await oft.quoteSend(params, false)
    const nativeFee = feeQuote.nativeFee

    console.log("Fee is: " + nativeFee)
    const tx = await oft.send(params, {nativeFee: nativeFee, lzTokenFee: 0}, signer.address, {
        value: nativeFee,
    });

    await tx.wait()
}


main().then(() => process.exit(0))