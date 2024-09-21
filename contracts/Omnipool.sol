// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import { IOAppComposer } from "@layerzerolabs/oapp-evm/contracts/oapp/interfaces/IOAppComposer.sol";
import { OFTComposeMsgCodec } from "@layerzerolabs/oft-evm/contracts/libs/OFTComposeMsgCodec.sol";
import { MessagingFee, OFTReceipt, SendParam, IOFT } from "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/interfaces/IOFT.sol";
import { OptionsBuilder } from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/libs/OptionsBuilder.sol";
import "./ITS/InterchainTokenExecutable.sol";
import "./IRouterV2.sol";
import "./IQuantumPortalPoc.sol";
import "./IDecimalConversion.sol";
import "./ISymbol.sol";


contract Omnipool is Ownable, InterchainTokenExecutable {
    using OptionsBuilder for bytes;

    uint256 constant LIQUIDITY_CHAIN_ID = 8453;

    uint256 feeFactor;
    uint256 remoteExecutionGas;
    uint256 qpFee;
    address public lzEndpoint;

    mapping (uint256 => address) public trustedRemotes;
    mapping(uint256 => uint32) private chainIdToLzEid;
    mapping(uint32 => uint256) private lzEidToChainId;
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
    error NotEndpoint();
    error ChainNotSet();

    event OApp(address);
    event Fees(uint256);
    event Logging(bytes);
    event LoggingString(string);
    event If();
    event Else();

    modifier onlyPortal() {
        if (msg.sender != address(portal)) revert NotPortal();
        _;
    }

    constructor(
        address _portal,
        address _lzEndpoint,
        address _routerV2,
        address _interchainTokenService,
        address _gasService
    ) Ownable(tx.origin) InterchainTokenExecutable(_interchainTokenService) {
        portal = IQuantumPortalPoc(_portal);
        routerV2 = IRouterV2(_routerV2);
        gasService = IInterchainGasService(_gasService);
        lzEndpoint = _lzEndpoint;
        feeFactor = 102;
        remoteExecutionGas = 600000;
        qpFee = 1000 ether;
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
            bytes memory payload = abi.encodeWithSignature("swapAndTransfer(uint256,uint256,address,address)", amountIn, amountOutMin, path[1], msg.sender);
            
            IERC20(portal.feeToken()).transfer(portal.feeTarget(), qpFee);
            portal.run(
                uint64(LIQUIDITY_CHAIN_ID),
                trustedRemotes[LIQUIDITY_CHAIN_ID],
                owner(),
                payload
            );
        } else {
            bytes memory payload = abi.encode(amountOutMin, path[0], msg.sender);

            if (_isITS(path[0])) {
                _handleITSTransfer(amountIn, path[0], payload, remoteExecutionGas, LIQUIDITY_CHAIN_ID);
            } else {
                _handleOFTTransfer(amountIn, path[0], payload, remoteExecutionGas, LIQUIDITY_CHAIN_ID);
            }
        }
    }

    function release(uint256 amount, address recipient) external onlyPortal {
        (uint256 sourceChainId, address remoteCaller,) = portal.msgSender();
        if (trustedRemotes[sourceChainId] != remoteCaller) revert NotTrustedRemote();
        bridgeToken.transfer(recipient, amount);
    }

    function swapAndTransfer(uint256 amountIn, uint256 amountOutMin, address toToken, address recipient) external onlyPortal {
        (uint256 sourceChainId, address remoteCaller,) = portal.msgSender();
        if (trustedRemotes[sourceChainId] != remoteCaller) revert NotTrustedRemote();

        uint256 amountOut = _swap(amountIn, amountOutMin, address(bridgeToken), toToken);

        // lz Transfer
        bytes memory payload = abi.encode(recipient, toToken);

        if (_isITS(toToken)) {
            _handleITSTransfer(amountOut, toToken, payload, 60_000, sourceChainId);
        } else {
            _handleOFTTransfer(amountOut, toToken, payload, 60_000, sourceChainId);
        }
    }

    function lzCompose(
        address _oApp,
        bytes32 /*_guid*/,
        bytes calldata _message,
        address /*Executor*/,
        bytes calldata /*Executor Data*/
    ) external payable {
        emit Logging(_message);
        if (msg.sender != lzEndpoint) revert NotEndpoint();
        emit OApp(_oApp);

        uint256 amount = OFTComposeMsgCodec.amountLD(_message);
        bytes memory _composeMessage = OFTComposeMsgCodec.composeMsg(_message);
        uint32 srcEid = OFTComposeMsgCodec.srcEid(_message);

        if (_composeMessage.length == 0x40) {
            (address recipient, address token) = abi.decode(_composeMessage, (address, address));
            IERC20(token).transfer(recipient, amount);
        } else {
            (uint256 amountOutMin, address token, address recipient) = abi.decode(_composeMessage, (uint256, address, address));
            
            uint256 srcChainId = _getChainId(srcEid);
            uint256 amountOut = _swap(amount, amountOutMin, token, address(bridgeToken));

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

    function setChainIdKeys(uint256[] memory chainIds, uint32[] memory lzEids, string[] memory chainNames) external onlyOwner {
        for (uint256 i = 0; i < chainIds.length; i++) {
            chainIdToLzEid[chainIds[i]] = lzEids[i];
            chainIdToName[chainIds[i]] = chainNames[i];
            lzEidToChainId[lzEids[i]] = chainIds[i];
            chainNameToId[chainNames[i]] = chainIds[i];
        }
    }

    function setFeeFactor(uint256 _feeFactor) external onlyOwner {
        feeFactor = _feeFactor;
    }

    function setRemoteExecutionGas(uint256 gas) external onlyOwner {
        remoteExecutionGas = gas;
    }

    function setQpFee(uint256 fee) external onlyOwner {
        qpFee = fee;
    }

    function setBridgeToken(address _bridgeToken) external onlyOwner {
        bridgeToken = IERC20(_bridgeToken);
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
        assembly {
            addr := mload(add(bytesAddress, 20))
        }
    }

    function _toBytes32(address addr) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(addr)));
    }

    function _toBytes(address addr) internal pure returns (bytes memory bytesAddress) {
        bytesAddress = new bytes(20);
        assembly {
            mstore(add(bytesAddress, 20), addr)
            mstore(bytesAddress, 20)
        }
    }

    function _getChainId(uint32 lzEid) internal view returns (uint256) {
        uint256 chainId = lzEidToChainId[lzEid];
        if (chainId == 0) revert ChainNotSet();
        return chainId;
    }

    function _getChainId(string memory chainName) internal view returns (uint256) {
        uint256 chainId = chainNameToId[chainName];
        if (chainId == 0) revert ChainNotSet();
        return chainId;
    }

    function _getLzEid(uint256 chainId) internal view returns (uint32) {
        uint32 lzEid = chainIdToLzEid[chainId];
        if (lzEid == 0) revert ChainNotSet();
        return lzEid;
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

    function _isITS(address token) public view returns (bool) {
        string memory symbol = ISymbol(token).symbol();
        string memory itsSymbol = "x-ITS";
        if (_isEqualStrings(symbol, itsSymbol)) {
            return true;
        } else {
            return false;
        }
    }

    function _isEqualStrings(string memory a, string memory b) internal pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }

    function _removeDust(uint256 _amountLD, address _token) internal view virtual returns (uint256 amountLD) {
        uint256 decimalConversionRate = IDecimalConversionRate(_token).decimalConversionRate();
        return (_amountLD / decimalConversionRate) * decimalConversionRate;
    }

    function _swap(uint256 amountIn, uint256 amountOutMin, address fromToken, address toToken) internal returns (uint256){
        IERC20(fromToken).approve(address(routerV2), amountIn);
        address[] memory swapPath = new address[](2);
        swapPath[0] = fromToken;
        swapPath[1] = toToken;

        uint256[] memory amounts = routerV2.swapExactTokensForTokens(
            amountIn,
            amountOutMin,
            swapPath,
            address(this),
            block.timestamp + 10
        );

        return amounts[1];
    }

    function _handleOFTTransfer(uint256 amount, address token, bytes memory payload, uint256 remoteGas, uint256 targetChainId) internal {
        bytes memory extraOptions = OptionsBuilder.newOptions()
            .addExecutorLzReceiveOption(60_000, 0)
            .addExecutorLzComposeOption(0, uint128(remoteGas), 0);

        SendParam memory sendParam = SendParam({
            dstEid: _getLzEid(targetChainId),
            to: _toBytes32(trustedRemotes[targetChainId]),
            amountLD: _removeDust(amount, token),
            minAmountLD: _removeDust(amount, token),
            extraOptions: extraOptions,
            composeMsg: payload,
            oftCmd: ""
        });

        MessagingFee memory fee = IOFT(token).quoteSend(sendParam, false);

        IOFT(token).send{value: fee.nativeFee}(sendParam, fee, msg.sender);
    }

    function _handleITSTransfer(uint256 amount, address token, bytes memory payload, uint256 remoteGas, uint256 targetChainId) internal {
        uint256 itsGas = gasService.estimateGasFee(
            _getChainName(targetChainId),
            string(_toBytes(trustedRemotes[targetChainId])),
            payload,
            remoteGas,
            new bytes(0)
        ) * feeFactor / 100; // buffer

        IInterchainTokenService(interchainTokenService).callContractWithInterchainToken{value: itsGas}(
            IInterchainTokenStandard(token).interchainTokenId(),
            _getChainName(targetChainId),
            _toBytes(trustedRemotes[targetChainId]),
            amount,
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

        if (data.length == 0x40) {
            (address recipient,) = abi.decode(data, (address, address));
            IERC20(token).transfer(recipient, amount);
        } else {
            IERC20(token).approve(address(routerV2), amount);

            (uint256 amountOutMin,,address recipient) = abi.decode(data, (uint256, address, address));
            
            uint256 srcChainId = _getChainId(sourceChain);
            uint256 amountOut = _swap(amount, amountOutMin, token, address(bridgeToken));

            IERC20(portal.feeToken()).transfer(portal.feeTarget(), qpFee);
            portal.run(
                uint64(srcChainId),
                trustedRemotes[srcChainId],
                owner(),
                abi.encodeWithSignature("release(uint256,address)", amountOut, recipient)
            );
        }
    }

    function receiveNative() external payable {} // Hardhat ignition
}
