import { buildModule } from "@nomicfoundation/hardhat-ignition/modules"


const deployModule = buildModule("FeeTokenDeploy", (m) => {    
    const token = m.contract("FeeToken", [], { id: "TestToken"})
    return {token}
})

export default deployModule;
