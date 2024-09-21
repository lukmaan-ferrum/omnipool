import hre from "hardhat";

let usdc;
const qpFeeToken = "0x6D34420DcAf516bEc9D81e5d79FAC2100058C9AC"


async function main() {
    
    if (hre.network.name === "arbitrumOne") {
        usdc = "0xaf88d065e77c8cC2239327C5EDb3A432268e5831"
    } else {
        usdc = "0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913"
    }

    const signer = await hre.ethers.provider.getSigner()
    const omnipool = await hre.ethers.getContractAt("Omnipool", "0x9dD868dD5a7611e4FC17D82F67dcD0b3A0730532", signer)

    await omnipool["sweepNative()"]()
    await omnipool.sweepTokens([usdc, qpFeeToken])
}

main().then(() => process.exit(0))
