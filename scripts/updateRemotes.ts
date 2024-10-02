import hre from "hardhat";


const srcOmnipoolAddr = "0xd8b7a9401A23e91DAf2c53fB04DC48ea782A6875"
const dstOmnipoolAddr = "0xd8b7a9401A23e91DAf2c53fB04DC48ea782A6875"    

async function main() {
    
    const signer = await hre.ethers.provider.getSigner()
    const omnipool = await hre.ethers.getContractAt("Omnipool", srcOmnipoolAddr, signer)

    await omnipool.updateRemotePeers([42161, 10, 137], [dstOmnipoolAddr, dstOmnipoolAddr, dstOmnipoolAddr])
}

main().then(() => process.exit(0))
