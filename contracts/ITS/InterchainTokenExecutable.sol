// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IInterchainTokenExecutable {
    function executeWithInterchainToken(
        bytes32 commandId,
        string calldata sourceChain,
        bytes calldata sourceAddress,
        bytes calldata data,
        bytes32 tokenId,
        address token,
        uint256 amount
    ) external returns (bytes32);
}

interface IInterchainTokenService {
    function callContractWithInterchainToken(
        bytes32 tokenId,
        string calldata destinationChain,
        bytes calldata destinationAddress,
        uint256 amount,
        bytes calldata data,
        uint256 gasValue
    ) external payable;
}

interface IInterchainTokenStandard {
    function interchainTokenId() external view returns (bytes32);
}

interface IInterchainGasService {
    function estimateGasFee(
        string calldata destinationChain,
        string calldata destinationAddress,
        bytes calldata payload,
        uint256 executionGasLimit,
        bytes calldata params
    ) external view returns (uint256 gasEstimate);
}

abstract contract InterchainTokenExecutable is IInterchainTokenExecutable {
    error NotService(address caller);

    address public immutable interchainTokenService;

    bytes32 internal constant EXECUTE_SUCCESS = keccak256('its-execute-success');

    /**
     * @notice Creates a new InterchainTokenExecutable contract.
     * @param interchainTokenService_ The address of the interchain token service that will call this contract.
     */
    constructor(address interchainTokenService_) {
        interchainTokenService = interchainTokenService_;
    }

    /**
     * Modifier to restrict function execution to the interchain token service.
     */
    modifier onlyService() {
        if (msg.sender != interchainTokenService) revert NotService(msg.sender);
        _;
    }

    /**
     * @notice Executes logic in the context of an interchain token transfer.
     * @dev Only callable by the interchain token service.
     * @param commandId The unique message id.
     * @param sourceChain The source chain of the token transfer.
     * @param sourceAddress The source address of the token transfer.
     * @param data The data associated with the token transfer.
     * @param tokenId The token ID.
     * @param token The token address.
     * @param amount The amount of tokens being transferred.
     * @return bytes32 Hash indicating success of the execution.
     */
    function executeWithInterchainToken(
        bytes32 commandId,
        string calldata sourceChain,
        bytes calldata sourceAddress,
        bytes calldata data,
        bytes32 tokenId,
        address token,
        uint256 amount
    ) external virtual onlyService returns (bytes32) {
        _executeWithInterchainToken(commandId, sourceChain, sourceAddress, data, tokenId, token, amount);
        return EXECUTE_SUCCESS;
    }

    /**
     * @notice Internal function containing the logic to be executed with interchain token transfer.
     * @dev Logic must be implemented by derived contracts.
     * @param commandId The unique message id.
     * @param sourceChain The source chain of the token transfer.
     * @param sourceAddress The source address of the token transfer.
     * @param data The data associated with the token transfer.
     * @param tokenId The token ID.
     * @param token The token address.
     * @param amount The amount of tokens being transferred.
     */
    function _executeWithInterchainToken(
        bytes32 commandId,
        string calldata sourceChain,
        bytes calldata sourceAddress,
        bytes calldata data,
        bytes32 tokenId,
        address token,
        uint256 amount
    ) internal virtual;
}