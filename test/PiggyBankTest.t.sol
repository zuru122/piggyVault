// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import "forge-std/Test.sol";
import "../src/PiggyBank.sol";
import "../src/PiggyUser.sol";
import "../src/interface/IERC20.sol";

contract PiggyBankTest is Test {
    PiggyUser factory;
    PiggyBank piggyBank;

    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address constant USDC_WHALE = 0x37305B1cD40574E4C5Ce33f8e8306Be057fD7341;

    address whale = 0x55FE002aefF02F77364de339a1292923A15844B8;

    address alice     = makeAddr("alice");
    address developer = makeAddr("developer");

    uint256 futureDeadline;

    function setUp() public {
        // Fork mainnet — run with: forge test --fork-url $ETH_RPC_URL -vvv
        vm.createSelectFork("https://eth-mainnet.g.alchemy.com/v2/ZE_JFcHdE8WB7w0eR_Zd3-W0zGmS74ZU");

        futureDeadline = block.timestamp + 30 days;

        // Developer deploys factory
        vm.prank(developer);
        factory = new PiggyUser();

        // creates a piggy bank
        vm.prank(whale);
        factory.savingPurpose("Vacation Fund", futureDeadline);

        // Get piggy bank
        PiggyUser.PiggyDetails[] memory banks = factory.getUserPiggyBanks(whale);
        piggyBank = PiggyBank(banks[0].piggyContractAddress);

        // Fund  with USDC via whale
        vm.prank(whale);
        IERC20(USDC).transfer(USDC_WHALE, 100e6);
    }

    // 1. Factory deploys piggy bank correctly
    function test_factoryCreatesPiggyBank() public {
        assertEq(piggyBank.owner(), whale);
        assertEq(piggyBank.purpose(), "Vacation Fund");
        assertEq(piggyBank.deadline(), futureDeadline);
    }

    // 2.  can deposit USDC
    function test_deposit() public {
        vm.startPrank(whale);
        IERC20(USDC).approve(address(piggyBank), 1_000e6);
        piggyBank.deposit(1_000e6, USDC);
        vm.stopPrank();

        assertEq(piggyBank.balances(whale, USDC), 1_000e6);
    }

    // 3. Withdraw before deadline applies 15% penalty
    function test_withdraw_beforeDeadline() public {
        vm.startPrank(whale);
        IERC20(USDC).approve(address(piggyBank), 1_000e6);
        piggyBank.deposit(1_000e6, USDC);

        uint256 balanceBefore = IERC20(USDC).balanceOf(alice);
        piggyBank.withdraw(USDC);
        uint256 balanceAfter = IERC20(USDC).balanceOf(alice);
        vm.stopPrank();

        // 15% penalty → alice gets 850 USDC back
        assertEq(balanceAfter - balanceBefore, 850e6);
    }

    // 4. Withdraw after deadline gives full amount
    function test_withdraw_afterDeadline() public {
        vm.startPrank(whale);
        IERC20(USDC).approve(address(piggyBank), 1_000e6);
        piggyBank.deposit(1_000e6, USDC);

        vm.warp(futureDeadline + 1); // fast forward time

        uint256 balanceBefore = IERC20(USDC).balanceOf(alice);
        piggyBank.withdraw(USDC);
        uint256 balanceAfter = IERC20(USDC).balanceOf(alice);
        vm.stopPrank();

        // No penalty → alice gets full 1000 USDC back
        assertEq(balanceAfter - balanceBefore, 1_000e6);
    }

    // 5. Unauthorized user cannot withdraw
    function test_withdraw_revertsIfNotOwner() public {
        address bob = makeAddr("bob");
        vm.prank(bob);
        vm.expectRevert(PiggyBank.Unauthorized.selector);
        piggyBank.withdraw(USDC);
    }
}