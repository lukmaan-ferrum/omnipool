import hre from "hardhat";


const oftAddr = "0xe6388F7c0f7ad74f5F82693EfB46C021EaE976e0"

async function main() {
    
    const signer = await hre.ethers.provider.getSigner()
    const testOft = await hre.ethers.getContractAt("TestOFT", oftAddr, signer)
    const oftAddrInBytes32 = "0x" + oftAddr.slice(2).padStart(64, "0")

    await testOft.setPeer(30110n, oftAddrInBytes32)
}

main().then(() => process.exit(0))
