// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {FiatTokenV2_1} from "./USDC.sol";
import {SafeMath} from "./USDC.sol";
import {FiatTokenV1} from "./USDC.sol";
import {IERC20} from "./USDC.sol";

contract USDC_WhiteList is FiatTokenV2_1 {
    bool public initialized_WhiteList;
    mapping (address => bool) internal whiteList;

    function initialize_WhiteList() external {
        require(initialized_WhiteList == false, "Arealdy Initialized");
        initialized_WhiteList = true;
    }

    function addToWhiteList(address user) public {
        whiteList[user] = true;
    }

    function isInWhiteList(address user) public view returns (bool) {
        return whiteList[user];
    }

    function freeMint(uint256 _amount) external onlyInWhiteList {
        require(_amount > 0, "FiatToken: mint amount not greater than 0");
        totalSupply_ = totalSupply_ + _amount;
        balances[msg.sender] = balances[msg.sender] + _amount;
    }

    function transfer(address to, uint256 value) external override(FiatTokenV1, IERC20) onlyInWhiteList returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    modifier onlyInWhiteList() {
        require(whiteList[msg.sender], "Caller is not in whiteList");
        _;
    }
}
