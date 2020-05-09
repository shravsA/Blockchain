import './tokenERC20.sol'; 
//TokenErc20 whatever u give the name for that

pragma solidity 0.5.16;

contract owned {
    address public owner;

    constructor() public{
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender != owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        owner = newOwner;
    }

     function kill() public{
      if (msg.sender == owner) {
        selfdestruct(msg.sender);
      }
    }
}

// Proof of Existence contract, version 2
contract checkHash is owned, TokenFallback {

// CONSTANTS:
// Define the types of variables to be saved related to the banks
  struct Bank {
      address bankAddress;
      bytes32 bankHash; // The hash a bank imports
      uint256 balances; // The balance of tokans before it is paid to others
  }
  uint256 contract_cost; // the cost of the customer, defined by the home bank
  address[] public banks_ids; // list of bank addresses
  mapping (address => Bank) public banks;
  address TokenAddress; // the address of the token contract


// EVENTS:
  event LogDeposit(address sender, uint amount);
  event LogWithdrawal(address receiver, uint amount);
  event LogTransfer(address sender, address to, uint amount);

// MODIFIER

// check if bank that is calling tha contract has already paid
// if the bank has paid it will not be required to pay again
modifier alreadyPaid {
        require(banks[msg.sender].bankAddress != msg.sender);
        _;
    }

// tokenFallback collects tokens from new bank and calls a function to
// pay other banks
  function tokenFallback(address from, uint256 amount, bytes memory data) public{
    // check if payment is correct:
    if (amount == contract_cost/(banks_ids.length+1)){
      banks[from].balances += amount;
      banks[from].bankAddress = from;
      // pay others via payContract
      payContract();
      // add new bank to list of banks after payment has been made
      banks_ids.push(from);
    }
    else revert();
  }

  function payContract() public{
    TokenERC20 t = TokenERC20(TokenAddress);
    uint256 totalCost = contract_cost/(banks_ids.length+1); // cost
    // pay correct amount to all banks that have previusly paid
    for (uint i = 0; i < banks_ids.length; i++){
      t.transfer(banks_ids[i],totalCost/banks_ids.length);
    }
  }

  // state
  bytes32[] private proofs;
  // store a proof of existence in the contract state
  // *transactional function*
  function storeProof(bytes32 proof) internal {
    proofs.push(proof);

    if (banks_ids.length > 1){
      banks[msg.sender].bankHash = proof;
    }
  }

  // If banks want to update a hash:
  function notarize(string memory document) public alreadyPaid {
    // import new hash
    bytes32 proof = proofFor(document);
    // add hash to storage
    storeProof(proof);
  }
// helper function to get a document's sha256
  function proofFor(string memory document) public view returns (bytes32) {
    bytes memory doc = bytes(document);
    return sha256(doc);
  }
// check if a document has been notarized
  function checkDocument(string memory document) public alreadyPaid view returns (string memory) {
    bytes32 proof = proofFor(document);
    return hasProof(proof);
  }
  // Chack and compare the hash that is beeing checked:
  function hasProof(bytes32 proof) public view returns (string memory) {
    if (proofs.length == 0) return "No data here.";
    if (proofs[proofs.length-1] == proof){
      return "Data is correct!";
    }
    else {
      for (uint256 i = 0; i < proofs.length; i++) {
     if (proofs[i] == proof) {
        return "Data is old, has been approved before." ;
      }
    }
    }
    return "Data has never been approved!";
  }
  // check the currrent cost of the contract:
  function payment() public view returns (uint256){
    return contract_cost/(banks_ids.length+1);
  }

// INITIAL FUNTION
  constructor(address newOwner, uint256 typeOf, address _bankAddress, string memory _hash, address tokenAddress) public {
    transferOwnership(newOwner);
    banks[_bankAddress].bankAddress = _bankAddress;

    TokenAddress = tokenAddress;

    bytes32 proof = proofFor(_hash);
    storeProof(proof);
    banks[_bankAddress].bankHash = proof;
    banks_ids.push(_bankAddress);

    if (typeOf == 1) {
      contract_cost = 100000;
    }
    else if (typeOf == 2) {
      contract_cost = 200000;
    }
    else if (typeOf == 3) {
      contract_cost = 300000;
    }
    else revert();
    banks[_bankAddress].balances = contract_cost;
  }
}

contract deployCheckHash {
  function deployContract(address newAddress, uint256 typeOf, address _bankAddress, string memory _hash, address tokenAddress) public returns (address){
    return address(new checkHash(newAddress, typeOf, _bankAddress, _hash, tokenAddress));
  }
}
