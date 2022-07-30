// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.6;
import "@openzeppelin/contracts/token/ERC777/ERC777.sol";

// import "openzeppelin-contracts/contracts/access/Ownable.sol";



/**
* todo: set decimals to 0
*/
contract IOU {

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

    function paydownDebtWithDebt(address lender, address borrower, address subBorrower, uint256 amount) public {
        require(balanceBorrowed(lender, borrower) >= amount, "Not enough debt");
        require(balanceBorrowed(borrower, subBorrower) >= amount, "Not enough debt");
        paydownDebt(lender, borrower, amount);
        transferDebt(borrower, lender, subBorrower, amount);
    }
}
