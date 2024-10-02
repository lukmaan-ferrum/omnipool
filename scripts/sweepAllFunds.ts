import hre from "hardhat";

let usdc;
const qpFeeToken = "0x17e439f8FDF9Ae414E9BB1e414733a27A9322B7e"


async function main() {
    
    if (hre.network.name === "arbitrumOne") {
        usdc = "0xaf88d065e77c8cC2239327C5EDb3A432268e5831"
    } else {
        usdc = "0x3c499c542cEF5E3811e1192ce70d8cC03d5c3359"
    }

    const signer = await hre.ethers.provider.getSigner()
    const omnipool = await hre.ethers.getContractAt("Omnipool", "0xb4a2691A7e4bEFBdc27044225aebe9321Aa83D96", signer)

    await omnipool["sweepNative()"]()
    await omnipool.sweepTokens([usdc, qpFeeToken])
}

main().then(() => process.exit(0))
