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
contract IOU is ERC777, DSTest {

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

    constructor(
        uint256 initialSupply,
        address[] memory defaultOperators
    )
        ERC777("Gold", "GLD", defaultOperators)

    {
        _mint(msg.sender, initialSupply, "", "", true);
        allLoans.push();
    }
    
    function lenderTotalLent(address lender) public view returns (uint256) {
        return lenderMapping[lender].totalAmount;
    }

    function borrowerTotalBorrowed(address borrower) public view returns (uint256) {
        return borrowerMapping[borrower].totalAmount;
    }

    function totalSupply() public override view returns (uint256) {
        return _totalSupply;
    }


    /**
     * Issue debt and transfer it to borrower.
     * TODO: require signatures from borrower and lender. Or just one from borrower and have lender issue the debt.
    * TODO: require to not overlow
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
            lenderAccount.counterparties.push(borrower);
            borrowerAccount.counterparties.push(lender);
            
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
    TODO: require to not overlow
    */
    function transferDebt(
        address origLender,
        address newLender,
        address borrower,
        uint256 amount
    ) public {
        require(amount > 0, "amount must be greater than 0");
        require(origLender != newLender, "Can't transfer to yourself");
        
        // bytes32 origLoan = keccak256(abi.encode(origLender, borrower));
        // bytes32 newLoan = keccak256(abi.encode(newLender, borrower));
        // uint256 outStanding = borrowedAmount[origLoan];
        // require(outStanding >= amount, "Not enough debt");
        // borrowedAmount[origLoan] = outStanding - amount;
        // uint256 oldLoanAmount = borrowedAmount[newLoan];
        // uint256 newLoanAmount = oldLoanAmount + amount;
        // require(newLoanAmount > oldLoanAmount, "Overflow");
        // borrowedAmount[newLoan] = newLoanAmount;
        //  += amount;

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

    function testExample() public {
        Borrower borrower = new Borrower();
        Lender lender = new Lender();

        // require(1 == 2, "aaa");
        address[] memory defaultOperators = new address[](1);
        defaultOperators[0] = address(this);
        IOU iou;
        iou = new IOU(10 * 1 ether, defaultOperators);
        // iou.send(address(lender), 1 ether, "Send some ethers to lender");
        // iou.operatorSend(address(lender), address(borrower), 1 ether, "", "");
        // emit log_named_uint("balance lender", iou.balanceOf(address(lender)));
        assertEq(iou.lenderTotalLent(address(lender)), 0);
        assertEq(iou.borrowerTotalBorrowed(address(borrower)), 0);
        
        iou.issueDebt(address(lender), address(borrower), 1);
        assertEq(iou.lenderTotalLent(address(lender)), 1);

        iou.issueDebt(address(lender), address(borrower), 1);
        assertEq(iou.lenderTotalLent(address(lender)), 2);
        assertEq(iou.borrowerTotalBorrowed(address(borrower)), 2);

        address borrower2 = address(0x1);
        iou.issueDebt(address(lender), borrower2, 1);
        assertEq(iou.lenderTotalLent(address(lender)), 3);
        assertEq(iou.borrowerTotalBorrowed(address(borrower)), 2);
        assertEq(iou.borrowerTotalBorrowed(address(borrower2)), 1);

        assertEq(iou.totalSupply(), 3);

    }
}

