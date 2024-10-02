import hre from "hardhat";


const oft = "0x3ca437941Db4b4797046bc7B814fD9C80293bC6a"
const its = "0xcE15516130F5293F9ae507C3b1cCCD4cA2c92640"

const omnipoolAddr = "0xd8b7a9401A23e91DAf2c53fB04DC48ea782A6875"

async function main() {

    let usdc
    if (hre.network.name === "arbitrumOne") {
        usdc = "0xaf88d065e77c8cC2239327C5EDb3A432268e5831"
    } else if (hre.network.name === "polygon") {
        usdc = "0x3c499c542cEF5E3811e1192ce70d8cC03d5c3359"
    } else if (hre.network.name === "optimism") {
        usdc = "0x0b2C639c533813f4Aa9D7837CAf62653d097Ff85"
    } else {
        throw new Error("Unsupported network")
    }

    const signer = await hre.ethers.provider.getSigner()
    const omnipool = await hre.ethers.getContractAt("Omnipool", omnipoolAddr, signer)
    
    await omnipool.omniswap(
        hre.ethers.parseEther("0.1"),
        // hre.ethers.parseUnits("0.03", 6),
        1,
        [its, usdc],
        // [usdc, oft],
        {gasLimit: 5000000}
    )
}

main().then(() => process.exit(0))
