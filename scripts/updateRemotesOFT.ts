import hre from "hardhat";


const oftAddr = "0x3ca437941Db4b4797046bc7B814fD9C80293bC6a"

async function main() {
    
    const signer = await hre.ethers.provider.getSigner()
    const testOft = await hre.ethers.getContractAt("XOFT", oftAddr, signer)
    const oftAddrInBytes32 = "0x" + oftAddr.slice(2).padStart(64, "0")

    await testOft.setPeer(30109n, oftAddrInBytes32)
}

main().then(() => process.exit(0))
