// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.6;

import "ds-test/test.sol";

import "./IOU.sol";
import "@openzeppelin/contracts/utils/introspection/ERC1820Implementer.sol";

// see also https://github.com/skalenetwork/skale-allocator/blob/5ffdf794df2850226a927d635431cec14939aefe/contracts/test/thirdparty/ERC777.sol


contract IOU_Test is DSTest {
    address lender = address(0x1);
    address borrower = address(0x2);
    address borrower2 = address(0x3);
    address lender2 = address(0x4);

    constructor()
    {
    }

    function setUp() public {
        //
        // iou = new IOU(10000000, defaultOperators);
        // IOU_Recipient r = new IOU_Recipient();

        // _ERC1820_REGISTRY.setInterfaceImplementer(address(this), keccak256("ERC777Token"), address(r));
        // _ERC1820_REGISTRY.setInterfaceImplementer(address(r), keccak256("ERC777Token"), address(r));

    }

    function testIOU_issueDebt(uint232 amountFuzz) public {
        uint256 amount = uint256(amountFuzz) + 1;

        IOU iou = new IOU();

        assertEq(iou.lenderTotalLent(lender), 0);
        assertEq(iou.borrowerTotalBorrowed(borrower), 0);

        iou.issueDebt(lender, borrower, 1 * amount);
        assertEq(iou.lenderTotalLent(lender), 1 * amount);
        assertEq(iou.balanceBorrowed(lender, borrower), 1 * amount);
        assertEq(iou.balanceBorrowed(borrower, lender), 0);

        iou.issueDebt(lender, borrower, 1 * amount);
        assertEq(iou.lenderTotalLent(lender), 2 * amount);
        assertEq(iou.borrowerTotalBorrowed(borrower), 2 * amount);

        iou.issueDebt(lender, borrower2, 1 * amount);
        assertEq(iou.lenderTotalLent(lender), 3 * amount);
        assertEq(iou.borrowerTotalBorrowed(borrower), 2 * amount);
        assertEq(iou.borrowerTotalBorrowed(borrower2), 1 * amount);

        assertEq(iou.totalSupply(), 3 * amount);
    }

    function testIOU_paydownDebt(uint232 amountFuzz) public {
        uint256 amount = uint256(amountFuzz) + 1;

        IOU iou = new IOU();

        iou.issueDebt(lender, borrower, 2 * amount);
        assertEq(iou.lenderTotalLent(lender), 2 * amount);
        assertEq(iou.borrowerTotalBorrowed(borrower), 2 * amount);

        iou.paydownDebt(lender, borrower, 1 * amount);
        assertEq(iou.lenderTotalLent(lender), 1 * amount);
        assertEq(iou.borrowerTotalBorrowed(borrower), 1 * amount);

        iou.paydownDebt(lender, borrower, 1 * amount);
        assertEq(iou.lenderTotalLent(lender), 0);
        assertEq(iou.borrowerTotalBorrowed(borrower), 0);
    }

    function testIOU_transferDebt(uint232 amountFuzz) public {
        uint256 amount = uint256(amountFuzz) + 1;

        IOU iou = new IOU();

        // issue 2 units of debt from borrower to lender
        iou.issueDebt(lender, borrower, 2 * amount);
        assertEq(iou.lenderTotalLent(lender), 2 * amount);
        assertEq(iou.borrowerTotalBorrowed(borrower), 2 * amount);

        // transfer half of debt lender->lender2
        iou.transferDebt(lender, lender2, borrower, amount);
        assertEq(iou.lenderTotalLent(lender), 1 * amount);
        assertEq(iou.borrowerTotalBorrowed(borrower), 2 * amount);
    }


    function testIOU_complicated_transferDebt(uint232 amountFuzz) public {
        uint256 amount = uint256(amountFuzz) + 1;
        IOU iou = new IOU();

        uint160 i = 1;
        address Joe = address(i++);
        address Bob = address(i++);
        address Carl = address(i++);
        iou.issueDebt(Joe, Bob, 2 * amount);
        iou.issueDebt(Bob, Carl, 1 * amount);
        emit log_named_uint("balance(Joe lent Bob)=", iou.balanceBorrowed(Joe, Bob));
        emit log_named_uint("balance(Bob lent Carl)=", iou.balanceBorrowed(Bob, Carl));
        emit log_named_uint("balance(Joe lent Carl)=", iou.balanceBorrowed(Joe, Carl));
        iou.paydownDebtWithDebt(Joe, Bob, Carl, 1 * amount);
        emit log_string("After payment via Carl's debt from Bob to Joe:");
        emit log_named_uint("balance(Joe lent Bob)=", iou.balanceBorrowed(Joe, Bob));
        emit log_named_uint("balance(Bob lent Carl)=", iou.balanceBorrowed(Bob, Carl));
        emit log_named_uint("balance(Joe lent Carl)=", iou.balanceBorrowed(Joe, Carl));

    }

}

