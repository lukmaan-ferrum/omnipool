import hre from "hardhat"
import {BigNumberish, BytesLike} from 'ethers';
import {Options} from '@layerzerolabs/lz-v2-utilities';
import {addressToBytes32} from '@layerzerolabs/lz-v2-utilities';



const main = async () => {
    const signer = await hre.ethers.provider.getSigner()

    const oftAddr = "0xe6388F7c0f7ad74f5F82693EfB46C021EaE976e0"
    const oft = await hre.ethers.getContractAt("TestOFT", oftAddr, signer) as any

    const amount = 10000000000000000000n

    const params = {
        dstEid: 30110,
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
    // const tx = await oft.send(params, {nativeFee: nativeFee, lzTokenFee: 0}, signer.address, {
    //     value: nativeFee,
    // });

    // await tx.wait()
}


main().then(() => process.exit(0))