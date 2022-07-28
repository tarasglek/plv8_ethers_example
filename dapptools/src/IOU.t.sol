// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.6;

import "ds-test/test.sol";

import "./IOU.sol";
import "@openzeppelin/contracts/utils/introspection/ERC1820Implementer.sol";

// see also https://github.com/skalenetwork/skale-allocator/blob/5ffdf794df2850226a927d635431cec14939aefe/contracts/test/thirdparty/ERC777.sol
/*

Need to add a map that maps from lenders to borrowers
Need to do 2-stage transfers by signing a message with borrower..such that it wont accept loans that arent signed by borrower

likewise when transferring loans between lenders, need to have receiver provide a signed authorization

*/
/**
* todo: set decimals to 0
*/
contract IOU is DSTest {

    struct Loan {
        address borrower;
        address lender;
        uint256 amount;
    }
    Loan[] private allLoans;

    struct Account {
        address[] counterparties;
        mapping (address => uint256) loans;
        uint256 totalAmount;
    }
    uint256 private _totalSupply = 0;

    mapping (address => Account) private lenderMapping;
    mapping (address => Account) private borrowerMapping;

    constructor()
    {
        // allLoans[0] is all zeroed out to make error-checking simpler
        allLoans.push();
    }

    function lenderTotalLent(address lender) public view returns (uint256) {
        return lenderMapping[lender].totalAmount;
    }

    function borrowerTotalBorrowed(address borrower) public view returns (uint256) {
        return borrowerMapping[borrower].totalAmount;
    }

    function balanceBorrowed(address lender, address borrower) public view returns (uint256) {
        return allLoans[borrowerMapping[borrower].loans[lender]].amount;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }


    /**
     * Issue debt and transfer it to borrower.
     * TODO: require signatures from borrower and lender. Or just one from borrower and have lender issue the debt.
     */
    function issueDebt(
        address lender,
        address borrower,
        uint256 amount
    ) public {
        require(amount > 0, "amount must be greater than 0");
        require(borrower != lender, "Can't lend to yourself");

        Account storage lenderAccount = lenderMapping[lender];
        Account storage borrowerAccount = borrowerMapping[borrower];

        Loan storage loan;
        uint256 loanIndex = lenderAccount.loans[borrower];
        // loanIndex == 0 means this is a new loan, so track it for both lender and borrower
        if (loanIndex == 0) {
            loanIndex = allLoans.length;
            loan = allLoans.push();
            // This is needed for accounting. Emitting events and then tracking those externally would also work.
            // lenderAccount.counterparties.push(borrower);
            // borrowerAccount.counterparties.push(lender);

            lenderAccount.loans[borrower] = loanIndex;
            borrowerAccount.loans[lender] = loanIndex;

            loan.borrower = borrower;
            loan.lender = lender;
        } else {
            loan = allLoans[loanIndex];
        }
        uint256 newLoanAmount = loan.amount + amount;
        uint256 newTotalAmountForLender = lenderAccount.totalAmount + amount;
        uint256 newTotalAmountForBorrower = borrowerAccount.totalAmount + amount;
        uint256 newTotalAmount = _totalSupply + amount;
        require(newLoanAmount > loan.amount && newTotalAmountForLender > lenderAccount.totalAmount && newTotalAmount > _totalSupply && newTotalAmountForBorrower > borrowerAccount.totalAmount, "Overflow");
        loan.amount = newLoanAmount;
        lenderAccount.totalAmount = newTotalAmountForLender;
        borrowerAccount.totalAmount = newTotalAmountForBorrower;
        _totalSupply = newTotalAmount;
    }

    /*
    * 1) this can be optimized when borrowed amount == amount transferred
    * 2) also an interesting case when newLender owes borrower.
    */
    function transferDebt(
        address origLender,
        address newLender,
        address borrower,
        uint256 amount
    ) public {
        require(origLender != newLender && newLender != borrower, "Can't transfer to yourself");
        issueDebt(newLender, borrower, amount);
        paydownDebt(origLender, borrower, amount);
    }

    function paydownDebt(address lender, address borrower, uint256 amount) public {
        Account storage lenderAccount = lenderMapping[lender];

        // update loan
        uint256 loanIndex = lenderAccount.loans[borrower];
        require(loanIndex != 0, "No loan found");
        Loan storage origLoan = allLoans[loanIndex];
        require(origLoan.amount >= amount, "Not enough debt");
        origLoan.amount -= amount;

        //update lender totalAmount
        require(lenderAccount.totalAmount >= amount, "This shouldn't happen after above check passes");
        lenderAccount.totalAmount = lenderAccount.totalAmount - amount;

        //update borrower totalAmount
        Account storage borrowerAccount = borrowerMapping[borrower];
        require(borrowerAccount.totalAmount >= amount, "This shouldn't happen after above checks pass");
        borrowerAccount.totalAmount = borrowerAccount.totalAmount - amount;
    }
}

contract PermissiveIERC777Recipient is DSTest, IERC777Recipient {
    string _name;
    IERC1820Registry constant internal _ERC1820_REGISTRY = IERC1820Registry(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24);
    bytes32 constant private TOKENS_RECIPIENT_INTERFACE_HASH = keccak256("ERC777TokensRecipient");

    constructor(string memory pName) {
        _name = pName;
        _ERC1820_REGISTRY.setInterfaceImplementer(address(this), TOKENS_RECIPIENT_INTERFACE_HASH, address(this));

    }

    function name() public view returns (string memory) {
        return _name;
    }

    // see https://github.com/NFTaftermarket/superXEROX2/blob/10ab89451023354fe131f7cfab926fcf4e4da938/contracts.bootstrap/Simple777Recipient.sol#L12
     function tokensReceived(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes memory, //userData,
        bytes memory //operatorData
    ) external override {
        // require(msg.sender == address(_token), "Simple777Recipient: Invalid token");

        // do nothing
        // emit DoneStuff(operator, from, to, amount, userData, operatorData);
        emit log_named_string("tokensReceived ", _name);
        emit log_named_address("  operator",  operator);
        if (from != address(0)  ) {
            emit log_named_string("  from",  PermissiveIERC777Recipient(from).name());
        }
        emit log_named_string("  to",  PermissiveIERC777Recipient(to).name());
        emit log_named_uint("  amount(eth)",  amount / (1 ether));
        emit log_named_address("  msg.sender",  msg.sender);

    }
}

contract Borrower is PermissiveIERC777Recipient {

    constructor()
        PermissiveIERC777Recipient("Borrower")
    {
    }
}

contract Lender is PermissiveIERC777Recipient {

    constructor()
        PermissiveIERC777Recipient("Lender")
    {
    }
}

contract IOU_Test is PermissiveIERC777Recipient {
    address lender = address(0x1);
    address borrower = address(0x2);
    address borrower2 = address(0x3);
    address lender2 = address(0x4);

    constructor()
        PermissiveIERC777Recipient("IOU_Test")
    {
    }
    function setUp() public {
        //
        // iou = new IOU(10000000, defaultOperators);
        // IOU_Recipient r = new IOU_Recipient();

        // _ERC1820_REGISTRY.setInterfaceImplementer(address(this), keccak256("ERC777Token"), address(r));
        // _ERC1820_REGISTRY.setInterfaceImplementer(address(r), keccak256("ERC777Token"), address(r));

    }

    function _testIOU_issueDebt(uint104 amount) public {
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

    function testIOU_issueDebt() public {
        // test with large amount
        _testIOU_issueDebt(0x0c9c754cd0b5e8c091eee27f2);
        // test small amount
        _testIOU_issueDebt(1);
    }

    function testIOU_paydownDebt() public {
        uint32 amount = 1;
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

    function testIOU_transferDebt() public {
        uint32 amount = 1;
        IOU iou = new IOU();

        // issue 2 units of debt from borrower to lender
        iou.issueDebt(lender, borrower, 2 * amount);
        assertEq(iou.lenderTotalLent(lender), 2 * amount);
        assertEq(iou.borrowerTotalBorrowed(borrower), 2 * amount);

        // transfer half of debt lender->lender2
        iou.transferDebt(lender, lender2, borrower, amount);
        assertEq(iou.lenderTotalLent(lender), 1 * amount);
        assertEq(iou.borrowerTotalBorrowed(borrower), 2 * amount);


        // paydown the transferred half
        iou.paydownDebt(lender2, borrower, amount);
        assertEq(iou.lenderTotalLent(lender2), 0);

        // lender2 borrows from borrower(opposite of 2nd block)
        iou.issueDebt(borrower, lender2, amount);
        emit log_named_uint("balance(borrower->lender2)=", iou.balanceBorrowed(borrower, lender2));

        assertEq(iou.borrowerTotalBorrowed(lender2), amount);
        //and transfers that loan to lender1..this should cancel out borrower's loan against lender
        iou.transferDebt(borrower, lender, lender2, amount);
        emit log_named_uint("balance(lender->borrowed)=", iou.balanceBorrowed(lender, borrower));
        emit log_named_uint("balance(borrowed->lender)=", iou.balanceBorrowed(borrower, lender));

        // iou.paydownDebt(lender, borrower, 1 * amount);
        // assertEq(iou.lenderTotalLent(lender), 0);
    }

}

