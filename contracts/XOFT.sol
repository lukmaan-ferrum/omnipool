// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { OFT } from "@layerzerolabs/oft-evm/contracts/OFT.sol";


contract XOFT is OFT {
    address constant ENDPOINT = 0x1a44076050125825900e736c501f859c50fE728c;
    constructor() OFT("x-OFT", "x-OFT", ENDPOINT, tx.origin) Ownable(tx.origin) {
        _mint(tx.origin, 1_000_000_000 ether);
    }
}
