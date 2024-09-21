// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./ITS/InterchainTokenExecutable.sol";
import "./IRouterV2.sol";
import "./IQuantumPortalPoc.sol";


contract OmnipooITS is Ownable, InterchainTokenExecutable {

    uint256 itsFeeFactor;
    uint256 remoteExecutionGas;
    uint256 qpFee;
    uint256 constant LIQUIDITY_CHAIN_ID = 56;

    mapping (uint256 => address) public trustedRemotes;
    mapping(uint256 => string) private chainIdToName;
    mapping(string => uint256) private chainNameToId;

    IERC20 bridgeToken;
    IQuantumPortalPoc public portal;
    IRouterV2 public routerV2;
    IInterchainGasService public gasService;

    error IncorrectPath();
    error InsufficientInput();
    error InsufficientLiquidity();
    error NotPortal();
    error NotTrustedRemote();
    error ChainNotSet();

    modifier onlyPortal() {
        if (msg.sender != address(portal)) revert NotPortal();
        _;
    }

    constructor(
        address _bridgeToken,
        address _portal,
        address _interchainTokenService,
        address _routerV2,
        address _gasService
    ) Ownable(tx.origin) InterchainTokenExecutable(_interchainTokenService) {
        bridgeToken = IERC20(_bridgeToken);
        portal = IQuantumPortalPoc(_portal);
        routerV2 = IRouterV2(_routerV2);
        gasService = IInterchainGasService(_gasService);
        itsFeeFactor = 110;
        remoteExecutionGas = 500000;
        qpFee = 0.01 ether;
    }

    function omniswap(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path
    ) external payable {
        if (amountIn == 0) revert InsufficientInput();
        IERC20(path[0]).transferFrom(msg.sender, address(this), amountIn);


        uint256 qpLeg = _determineQpLeg(path);
        if (qpLeg == 0) {
            bytes memory payload = abi.encodeWithSignature("swapAndITSTransfer(uint256,uint256,address,address)", amountIn, amountOutMin, path[1], msg.sender);
            
            IERC20(portal.feeToken()).transfer(portal.feeTarget(), qpFee);
            portal.run(
                uint64(LIQUIDITY_CHAIN_ID),
                trustedRemotes[LIQUIDITY_CHAIN_ID],
                owner(),
                payload
            );
        } else {
            bytes memory payload = abi.encode(amountOutMin, msg.sender);

            uint256 itsGas = gasService.estimateGasFee(
                _getChainName(LIQUIDITY_CHAIN_ID),
                string(_toBytes(trustedRemotes[LIQUIDITY_CHAIN_ID])),
                payload,
                remoteExecutionGas,
                new bytes(0)
            ) * itsFeeFactor / 100; // buffer

            IInterchainTokenService(interchainTokenService).callContractWithInterchainToken{value: itsGas}(
                IInterchainTokenStandard(path[0]).interchainTokenId(),
                _getChainName(LIQUIDITY_CHAIN_ID),
                _toBytes(trustedRemotes[LIQUIDITY_CHAIN_ID]),
                amountIn,
                payload,
                itsGas
            );
        }
    }

    function release(uint256 amount, address recipient) external onlyPortal {
        (uint256 sourceChainId, address remoteCaller,) = portal.msgSender();
        if (trustedRemotes[sourceChainId] != remoteCaller) revert NotTrustedRemote();
        bridgeToken.transfer(recipient, amount);
    }

    function swapAndITSTransfer(uint256 amount, uint256 amountOutMin, address toToken, address recipient) external onlyPortal {
        (uint256 sourceChainId, address remoteCaller,) = portal.msgSender();
        if (trustedRemotes[sourceChainId] != remoteCaller) revert NotTrustedRemote();

        IERC20(bridgeToken).approve(address(routerV2), amount);
        address[] memory path = new address[](2);
        path[0] = address(bridgeToken);
        path[1] = address(toToken);

        uint256[] memory amounts = routerV2.swapExactTokensForTokens(
            amount,
            amountOutMin,
            path,
            address(this),
            block.timestamp + 10
        );

        // ITS Transfer
        IERC20(toToken).approve(interchainTokenService, amounts[1]);
        bytes memory payload = abi.encode(recipient);

        uint256 itsGas = gasService.estimateGasFee(
                _getChainName(LIQUIDITY_CHAIN_ID),
                string(_toBytes(trustedRemotes[LIQUIDITY_CHAIN_ID])),
                payload,
                remoteExecutionGas,
                new bytes(0)
            ) * itsFeeFactor / 100; // buffer

        IInterchainTokenService(interchainTokenService).callContractWithInterchainToken{value: itsGas}(
            IInterchainTokenStandard(toToken).interchainTokenId(),
            _getChainName(sourceChainId),
            _toBytes(trustedRemotes[sourceChainId]),
            amounts[1],
            payload,
            itsGas
        );
    }

    function _executeWithInterchainToken(
        bytes32,
        string calldata sourceChain,
        bytes calldata sourceAddress,
        bytes calldata data,
        bytes32,
        address token,
        uint256 amount
    ) internal override {
        if (trustedRemotes[_getChainId(sourceChain)] != _toAddress(sourceAddress)) revert NotTrustedRemote();

        if (data.length == 0x20) {
            address recipient = abi.decode(data, (address));
            IERC20(token).transfer(recipient, amount);
        } else {
            IERC20(token).approve(address(routerV2), amount);

            (uint256 amountOutMin, address recipient) = abi.decode(data, (uint256, address));
            
            uint256 srcChainId = _getChainId(sourceChain);
            uint256 amountOut;
            {   
                address[] memory path = new address[](2);
                path[0] = address(token);
                path[1] = address(bridgeToken);

                uint256[] memory amounts = routerV2.swapExactTokensForTokens(
                    amount,
                    amountOutMin,
                    path,
                    address(this),
                    block.timestamp + 10
                );

                amountOut = amounts[1];
            }

            IERC20(portal.feeToken()).transfer(portal.feeTarget(), qpFee);
            portal.run(
                uint64(srcChainId),
                trustedRemotes[srcChainId],
                owner(),
                abi.encodeWithSignature("release(uint256,address)", amountOut, recipient)
            );
        }
    }

    //#############################################################
    //#################### ADMIN FUNCTIONS ########################
    //#############################################################
    function updateRemotePeers(uint256[] calldata chainIds, address[] calldata remotes) external onlyOwner {
        for (uint i=0; i<chainIds.length; i++) {
            trustedRemotes[chainIds[i]] = remotes[i];
        }
    }

    function removeRemotePeers(uint256[] calldata chainIds) external onlyOwner {
        for (uint i=0; i<chainIds.length; i++) {
            delete trustedRemotes[chainIds[i]];
        }
    }

    function setChainIdAndNamePairs(uint256[] memory chainIds, string[] memory chainNames) external onlyOwner {
        for (uint256 i = 0; i < chainIds.length; i++) {
            chainIdToName[chainIds[i]] = chainNames[i];
            chainNameToId[chainNames[i]] = chainIds[i];
        }
    }

    function setItsFeeFactor(uint256 feeFactor) external onlyOwner {
        itsFeeFactor = feeFactor;
    }

    function setRemoteExecutionGas(uint256 gas) external onlyOwner {
        remoteExecutionGas = gas;
    }

    function setQpFee(uint256 fee) external onlyOwner {
        qpFee = fee;
    }

    function sweepNative(uint256 amount) external onlyOwner {
        payable(owner()).transfer(amount);
    }

    function sweepNative() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function sweepToken(address token, uint256 amount) external onlyOwner {
        IERC20(token).transfer(owner(), amount);
    }

    function sweepTokens(address[] memory token) external onlyOwner {
        for (uint256 i = 0; i < token.length; i++) {
            IERC20(token[i]).transfer(owner(), IERC20(token[i]).balanceOf(address(this)));
        }
    }

    //#############################################################
    //#################### INTERNAL FUNCTIONS #####################
    //#############################################################
    function _toAddress(bytes memory bytesAddress) internal pure returns (address addr) {
        require(bytesAddress.length == 20, "ITSApp: Invalid address length");
        assembly {
            addr := mload(add(bytesAddress, 20))
        }
    }

    function _toBytes(address addr) internal pure returns (bytes memory bytesAddress) {
        bytesAddress = new bytes(20);
        assembly {
            mstore(add(bytesAddress, 20), addr)
            mstore(bytesAddress, 20)
        }
    }

    function _getChainId(string memory chainName) internal view returns (uint256) {
        
        uint256 chainId = chainNameToId[chainName];
        if (chainId == 0) revert ChainNotSet();
        return chainId;
    }

    function _getChainName(uint256 chainId) internal view returns (string memory) {
        string memory chainName = chainIdToName[chainId];
        if (bytes(chainName).length == 0) revert ChainNotSet();
        return chainName;
    }

    function _determineQpLeg(address[] calldata path) internal view returns (uint256) {
        if (path.length < 2) revert IncorrectPath();
        
        if (path[0] == address(bridgeToken)) {
            return 0;
        } else if (path[1] == address(bridgeToken)) {
            return 1;
        } else {
            revert IncorrectPath();
        }
    }

    function getNative() external payable {} // Hardhat ignition
}
