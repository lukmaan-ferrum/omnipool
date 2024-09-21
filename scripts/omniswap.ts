import hre from "hardhat";


const usdc = "0xaf88d065e77c8cC2239327C5EDb3A432268e5831"
const oft = "0xe6388F7c0f7ad74f5F82693EfB46C021EaE976e0"

const omnipoolAddr = "0x72C65D96F250B1DB2CA3D02b63DaFb034c84573f"

async function main() {

    const signer = await hre.ethers.provider.getSigner()
    const omnipool = await hre.ethers.getContractAt("Omnipool", omnipoolAddr, signer)
    
    await omnipool.omniswap(
        hre.ethers.parseEther("1.1"),
        1,
        [oft, usdc],
    )
}

main().then(() => process.exit(0))
