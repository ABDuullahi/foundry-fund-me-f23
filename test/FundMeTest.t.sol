// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../src/FundMe.sol";
import {DeployFundMe} from "../script/FundMe.s.sol";

contract FundMeTest is Test {
    FundMe fundMe;

    uint256 constant GAS_PRICE = 1;

    address USER = makeAddr("user");
    uint256 constant SEND_VALUE = 0.1 ether;
    uint256 constant STARTING_VALUE = 10 ether;

    function setUp() external {
        // fundMe = new FundMe(0x694AA1769357215DE4FAC081bf1f309aDC325306);

        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        vm.deal(USER, STARTING_VALUE);
    }

    modifier funded() {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        _;
    }

    function tester() public {
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function testOwnermsgsender() public {
        assertEq(fundMe.getOwner(), msg.sender);
    }

    function testPricefeedisacurate() public {
        uint256 version = fundMe.getVersion();
        assertEq(version, 4);
    }

    function testFailswithoutenoughETH() public {
        vm.expectRevert();
        fundMe.fund();
    }

    function testFundUpdated() public {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE};

        uint256 amountFunded = fundMe.addressToAmountFunded(USER);
        assertEq(amountFunded, SEND_VALUE);
    }

    function testaddsFunderstoarray() public {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE};

        address funder = fundMe.getFunder(0);
        assertEq(funder, USER);
    }

    function testeronlyownerandwithdraw() public funded {
        vm.prank(USER);
        vm.expectRevert();
        fundMe.withdraw();
    }

    function testwithdraws() public funded {
        uint256 startownerbalance = fundMe.getOwner().balance;
        uint256 startingFundmebalance = address(fundMe).balance;

        uint256 gasStart = gasleft();
        vm.txGasPrice(GAS_PRICE);
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();

        uint256 gasEnd = gasleft();
        uint256 gasUsed = (gasStart - gasEnd) * tx.gasprice;
        console.log(gasUsed);

        uint256 endingownerbalance = fundMe.getOwner().balance;
        uint256 endingFundmebalance = address(fundMe).balance;
        assertEq(endingFundmebalance, 0);
        assertEq(startingFundmebalance = startownerbalance, endingownerbalance);
    }

    function testwithdrawfrommultiple() public funded {
        uint160 numbberoffunders = 10;
        uint160 startingfunderindex = 1;
        for (uint160 i = startingfunderindex; i < numbberoffunders; i++) {
            hoax(address(i), SEND_VALUE);
            fundMe.fund{value: SEND_VALUE}();
        }

        uint256 startingOwnerbalance = fundMe.getOwner().balance;
        uint256 stratingfundmebalance = address(fundMe).balance;

        vm.startPrank(fundMe.getOwner());
        fundMe.withdraw();
        vm.stopPrank();

        assert(address(fundMe).balance == 0);
        assert(
            stratingfundmebalance + startingOwnerbalance ==
                fundMe.getOwner().balance
        );
    }

    function testwithdrawfrommultiplecheaper() public funded {
        uint160 numbberoffunders = 10;
        uint160 startingfunderindex = 1;
        for (uint160 i = startingfunderindex; i < numbberoffunders; i++) {
            hoax(address(i), SEND_VALUE);
            fundMe.fund{value: SEND_VALUE}();
        }

        uint256 startingOwnerbalance = fundMe.getOwner().balance;
        uint256 stratingfundmebalance = address(fundMe).balance;

        vm.startPrank(fundMe.getOwner());
        fundMe.cheaperWithdraw();
        vm.stopPrank();

        assert(address(fundMe).balance == 0);
        assert(
            stratingfundmebalance + startingOwnerbalance ==
                fundMe.getOwner().balance
        );
    }
}
