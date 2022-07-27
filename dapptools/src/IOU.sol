// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.6;
import "@openzeppelin/contracts/token/ERC777/ERC777.sol";

// import "openzeppelin-contracts/contracts/access/Ownable.sol";

contract IOU is ERC777 {
     constructor(
        uint256 initialSupply,
        address[] memory defaultOperators
    )
        ERC777("Gold", "GLD", defaultOperators)
        
    {
        _mint(msg.sender, initialSupply, "", "", true);
    }
}