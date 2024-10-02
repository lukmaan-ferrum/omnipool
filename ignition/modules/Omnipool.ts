import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import { ethers } from "hardhat";



const deployModule = buildModule("Omnipool", (m) => {

    const usdc = m.contractAt("IERC20", m.getParameter("bridgeToken"), {id: "hookUsdc"})
    const oft = m.contractAt("IERC20", m.getParameter("oft"), {id: "hookOFT"})
    const its = m.contractAt("IERC20", m.getParameter("its"), {id: "hookITS"})
    const qpFeeToken = m.contractAt("IERC20", m.getParameter("qpFeeToken"), {id: "hookQpFeeToken"})

    const omnipool = m.contract(
        "Omnipool",
        [
            m.getParameter("lzEndpoint"),
            m.getParameter("routerV2"),
            m.getParameter("interchainTokenService"),
            m.getParameter("gasService"),
        ], 
        {id: "deploy"}
    )
    m.call(omnipool, "setBridgeToken", [usdc], {id: "setBridgeToken"})
    m.call(omnipool, "setChainIdKeys", [[42161, 8453, 10, 137], [30110, 30184, 30111, 30109], ["arbitrum", "base", "optimism", "Polygon"]], {id: "setChainIdKeys"})

    m.call(usdc, "approve", [omnipool, ethers.MaxUint256], {id: "approveUsdc"})
    m.call(usdc, "transfer", [omnipool, 450000n], {id: "addLiquidity"})
    m.call(oft, "approve", [omnipool, ethers.MaxUint256], {id: "approveOFT"})
    m.call(its, "approve", [omnipool, ethers.MaxUint256], {id: "approveITS"})
    m.call(qpFeeToken, "transfer", [omnipool, 1000000000000000000000000n], {id: "addQpFeeToken"})
    m.call(omnipool, "receiveNative", [], {value: 200000000000000n, id: "sendNative"})
    m.call(omnipool, "setPortal", [m.getParameter("portal")], {id: "setPortal"})

    return {omnipool, usdc, oft}
})

export default deployModule
