import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";


const deployModule = buildModule("OFT", (m) => {
    const oft = m.contract("XOFT", [], {id: "deploy"})
    return {oft}
})

export default deployModule
