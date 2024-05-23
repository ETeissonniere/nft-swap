// SPDX-License-Identifier: MIT License

pragma solidity ^0.8.23;

import {ERC721Holder} from "openzeppelin-contracts/contracts/token/ERC721/utils/ERC721Holder.sol";

contract NftSwap is ERC721Holder {
    function onERC721Received(address, address, uint256, bytes memory) public pure override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}
