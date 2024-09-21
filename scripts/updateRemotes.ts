import hre from "hardhat";


const srcOmnipoolAddr = "0x72C65D96F250B1DB2CA3D02b63DaFb034c84573f"
const dstOmnipoolAddr = "0x9dD868dD5a7611e4FC17D82F67dcD0b3A0730532"    

async function main() {
    
    const signer = await hre.ethers.provider.getSigner()
    const omnipool = await hre.ethers.getContractAt("Omnipool", srcOmnipoolAddr, signer)

    await omnipool.updateRemotePeers([8453], [dstOmnipoolAddr])
}

main().then(() => process.exit(0))
