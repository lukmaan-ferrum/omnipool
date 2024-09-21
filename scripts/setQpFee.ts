import hre from "hardhat";


async function main() {
    
    const signer = await hre.ethers.provider.getSigner()
    const omnipool = await hre.ethers.getContractAt("Omnipool", "0x211c9F0eDFED505f6f98204d8b006205332D8E55", signer)

    await omnipool.setQpFee(10000000000000000000000n)
}

main().then(() => process.exit(0))
