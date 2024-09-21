import hre from "hardhat";


async function main() {
    
    const signer = await hre.ethers.provider.getSigner()
    const omnipool = await hre.ethers.getContractAt("Omnipool", "0x10bCBA38e0ef2572003F2aaC162201A555ed8f1F", signer)

    await omnipool.receiveNative(
        { value: 1000000000000000n}
    )
}

main().then(() => process.exit(0))