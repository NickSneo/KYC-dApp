// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract KYC{
	address public admin;
	uint private accountNumber=0;

	// enum Type { User, Admin, SuperAdmin }
	enum KYC_Status { NotExist, Pending, Approved, Rejected }
    enum Gender { Male, Female, Other }
	enum KYC_Priviliage { Allowed, Banned }

	// strcut for bankDetails
	struct bankDetails {
		string bankName;
        address bankAddress;
        uint256 kycCount;
		bool addCustomerPermission;
		KYC_Priviliage kycPrivilage;
	}

	// struct for Customers wrt Bank
	struct customer {
		uint accountNumber;
		string customerName;
		address customerAddress;
		customerData data;
		KYC_Status status;
		address customerBank;
		uint createdAt;
	}

	// strcut for customer Data
	struct customerData {
		uint age;
		Gender gender;
		string permanentAddress;
		string mobileNo;
	}

	mapping (address => bankDetails) private bankAddresses;
	mapping (uint256 => customer) private customerAccounts;

	event newBankAdded(address _bankAddress, string _bankName);
	event newCustomerAdded(uint _accountNumber, address _customerAddress);
	event kycDone(KYC_Status _kycApproved, uint _accountNumber, address _customerAddress, address _bankAddress);

	constructor(){
		admin = msg.sender;
	}

	// Check if the caller is an Admin.
	modifier onlyAdmin() {
		require(msg.sender == admin, "Only Admin can call this function");
		_;
	}

	// Check if the caller is a Bank.
	modifier onlyBanksOrAdmin() {
		require(msg.sender == bankAddresses[msg.sender].bankAddress || msg.sender == admin, "only admin or a Bank is allowed");
		_;
	}

	// Check if the Bank is approved for KYC
	modifier onlyKYCApprovedBanks() {
		require(msg.sender == bankAddresses[msg.sender].bankAddress, "only Bank is allowed to call this fucntion");
		require(bankAddresses[msg.sender].kycPrivilage == KYC_Priviliage.Allowed, "only KYC privilaged Bank is allowed to call this fucntion");
		_;
	}

	// Check if the Bank is approved for KYC
	modifier onlyAddCustApprovedBanks() {
		require(msg.sender == bankAddresses[msg.sender].bankAddress, "only Bank is allowed to call this fucntion");
		require(bankAddresses[msg.sender].addCustomerPermission == true, "only Bank with add Customer permission is allowed to call this fucntion");
		_;
	}

	// Check if the Bank is in database
	modifier checkIfBankExist(address bankAddress) {
		require(bankAddresses[bankAddress].bankAddress == bankAddress, "Bank details not in the database");
		_;
	}

	// Check if the Bank is in database
	modifier checkIfCustExist(uint accNumber) {
		require(customerAccounts[accNumber].accountNumber != 0, "Customer Information not in the Database, kindly enter correct Account Number");
		_;
	}


	// function to add new Bank to the database
	// can only be called by the admin
	function addNewBank (string memory bankName, address bankAddress) public onlyAdmin {
		bankAddresses[bankAddress] = bankDetails(bankName, bankAddress, 0, true, KYC_Priviliage.Allowed);
		emit newBankAdded(bankAddress, bankName);
	}

	// function to add new customer to the bank database
	// can only be called by a Bank with addCustomerPermission approved status
	function addNewCustomer (string memory customerName, address customerAddress, Gender gender, string memory PAN, uint age, string memory mobileNo) public onlyAddCustApprovedBanks returns (uint) {
		accountNumber++;
		customerData memory custData = customerData(age, gender, PAN, mobileNo);
		customerAccounts[accountNumber] = customer(accountNumber, customerName, customerAddress, custData, KYC_Status.NotExist, msg.sender, block.timestamp);
		emit newCustomerAdded(accountNumber, customerAddress);
		return accountNumber;
	}

	// function to check KYC of the customer wrt to their account Number
	function checkKYC (uint accNumber) public checkIfCustExist(accNumber) view returns (bool) {
		if (customerAccounts[accNumber].status == KYC_Status.Approved){
			return true;
		}
		return false;
	}

	// function to perform KYC of the customer if the bank has the right
	function doKYC (uint accNumber) public onlyKYCApprovedBanks checkIfCustExist(accNumber) {
		customerAccounts[accNumber].status = KYC_Status.Approved;
		bankAddresses[msg.sender].kycCount++;
		emit kycDone(KYC_Status.Approved, accNumber, customerAccounts[accNumber].customerAddress, msg.sender);
	}

	// function to block a Bank to add new Customers
	// can only be called by the admin
	function blockBankToAddCustomer (address bankAddress) public checkIfBankExist(bankAddress) onlyAdmin {
		bankAddresses[bankAddress].addCustomerPermission = false;
	}

	// function to block a Bank to do KYC
	// can only be called by the admin
	function blockBankToDoKYC (address bankAddress) public checkIfBankExist(bankAddress) onlyAdmin {
		bankAddresses[bankAddress].kycPrivilage = KYC_Priviliage.Banned;
	}

	// function to block a Bank to add new Customers
	// can only be called by the admin
	function allowBankToAddCustomer (address bankAddress) public checkIfBankExist(bankAddress) onlyAdmin {
		bankAddresses[bankAddress].addCustomerPermission = true;
	}

	// function to block a Bank to do KYC
	// can only be called by the admin
	function allowkBankToDoKYC (address bankAddress) public checkIfBankExist(bankAddress) onlyAdmin {
		bankAddresses[bankAddress].kycPrivilage = KYC_Priviliage.Allowed;
	}

	// function to return customer data wrt to their account Number
	function getCustomer (uint accNumber) public checkIfCustExist(accNumber) view returns (customer memory) {
		return (customerAccounts[accNumber]);
	}

}