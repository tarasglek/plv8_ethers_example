// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.6;

import "ds-test/test.sol";

import "./IOU.sol";

contract DapptoolsTest is DSTest {
    Dapptools dapptools;

    function setUp() public {
        dapptools = new Dapptools();
    }

    function testFail_basic_sanity() public {
        assertTrue(false);
    }

    function test_basic_sanity() public {
        assertTrue(true);
    }
}


contract ContractTest is DSTest {
    IOU iou;
    function setUp() public {
        // 
        // iou = new IOU(10000000, defaultOperators);
    }

    function testExample() public {
        // require(1 == 2, "aaa");
        address[] memory defaultOperators = new address[](1);
        defaultOperators[0] = address(this);
        iou = new IOU(10000000, defaultOperators);

        assertTrue(true);
    }
}
