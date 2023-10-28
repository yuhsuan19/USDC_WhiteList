// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {USDC_WhiteList} from "../src/USDC_WhiteList.sol";
import {IERC20} from "../src/USDC.sol";

interface USDCProxy {
    function upgradeToAndCall(address newImplementation, bytes calldata data) payable external;
    function upgradeTo(address newImplementation) external;
}

contract USDC_WhiteListTest is Test {
    uint256 public mainnet;
    address constant public usdcOwner = 0x807a96288A1A408dBC13DE2b1d087d10356395d2;
    address constant public usdcProxy = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

    address user1;
    address user2;

    USDC_WhiteList public usdcWhiteList;
    USDC_WhiteList public proxyUSDCWhiteList;

    function setUp() public {
        mainnet = vm.createFork("https://eth-mainnet.g.alchemy.com/v2/UUnnWhJdSk8fQt3D5h7kAZQNw8wY-PDx");
        vm.selectFork(mainnet);
        
        usdcWhiteList = new USDC_WhiteList();
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");
    }

    function test_upgrade() public {
        upgradeToVersionWithWhiteList();
        assert(proxyUSDCWhiteList.initialized_WhiteList());
    }

    function test_addToWhiteList() public {
        upgradeToVersionWithWhiteList();

        assert(proxyUSDCWhiteList.isInWhiteList(user1) == false);
        proxyUSDCWhiteList.addToWhiteList(user1);
        assert(proxyUSDCWhiteList.isInWhiteList(user1));
    }

    function test_freeMintInWhiteList() public {
        upgradeToVersionWithWhiteList();

        uint256 mintAmount = 1_000_000;

        uint256 balanceBeforeMint = proxyUSDCWhiteList.balanceOf(user1);
        freeMintForUser1(mintAmount);
        vm.startPrank(user1);
        uint256 balanceAfterMint = proxyUSDCWhiteList.balanceOf(user1);

        assertEq(balanceAfterMint, balanceBeforeMint + mintAmount);
    }

    function test_freeMintNotInWhiteList() public {
        upgradeToVersionWithWhiteList();

        vm.startPrank(user1);
        vm.expectRevert();
        proxyUSDCWhiteList.freeMint(1);
        vm.stopPrank();
    }

    function test_transfer() public {
        uint256 mintAmount = 1_000_000;
        uint256 transferAmount = 123_456;

        upgradeToVersionWithWhiteList();
        freeMintForUser1(mintAmount);

        vm.startPrank(user1);
        proxyUSDCWhiteList.transfer(user2, transferAmount);
        vm.stopPrank();

        assertEq(proxyUSDCWhiteList.balanceOf(user1), mintAmount - transferAmount);
        assertEq(proxyUSDCWhiteList.balanceOf(user2), transferAmount);

        vm.startPrank(user2);
        vm.expectRevert();
        proxyUSDCWhiteList.transfer(user1, 1);
        vm.stopPrank();
    }

    function upgradeToVersionWithWhiteList() private {
        vm.startPrank(usdcOwner);
        bytes memory initializedCalldata = abi.encodeWithSignature("initialize_WhiteList()");
        USDCProxy(usdcProxy).upgradeToAndCall(address(usdcWhiteList), initializedCalldata);
        vm.stopPrank();
        proxyUSDCWhiteList = USDC_WhiteList(usdcProxy);
    }

    function freeMintForUser1(uint256 _amount) private {
        proxyUSDCWhiteList.addToWhiteList(user1);
        vm.startPrank(user1);
        proxyUSDCWhiteList.freeMint(_amount);
        vm.stopPrank();
    }
}
