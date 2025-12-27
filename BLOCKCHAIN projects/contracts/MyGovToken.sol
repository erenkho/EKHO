pragma solidity ^0.4.24;
 


//Safe Math Interface

contract SafeMath {
 
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
 
    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
 
    function safeMul(uint a, uint b) public pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
 
    function safeDiv(uint a, uint b) public pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}
 
 
//ERC Token Standard #20 Interface
 
contract ERC20Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
    
    //allow users to call the requestTokens function to mint tokens
    function giveToken (address requestor) public returns (bool success);
    function donateEther(uint value) public payable returns (bool success);
    function donateMyGovToken(uint tokens) public payable returns (bool success);
    function buy(uint256 _amount, uint _value, address _sender) external payable;
    function sell(uint256 _amount, address _sender) external returns(uint pay);


    event DonateEther(address indexed donator,uint);
    event DonateToken(address indexed donator,uint tokens);
    event Mint(address indexed requestor);
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}
 


//Contract function to receive approval and execute function in one call
 
contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}


 
//Actual token contract
 
contract GovToken is ERC20Interface, SafeMath {
    string public symbol;
    string public  name;
    uint8 public decimals;
    uint public _totalSupply;
    address mainSupplyAddress= address(this);//0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    //when you requestTokens address and blocktime+1 day is saved in Time Lock
    mapping(address => bool) public minted;
    mapping(address => uint) public donatedEther;
    mapping(address => uint) public donatedToken;
    uint public donatedAmountEther;
    uint public donatedAmountToken;

    constructor(uint totalSupply) public {
        symbol = "MG";
        name = "MyGov";
        decimals = 2;
        _totalSupply = totalSupply;
        balances[mainSupplyAddress] = _totalSupply;
        emit Transfer(address(0), mainSupplyAddress, _totalSupply);
    }
 
    function totalSupply() public constant returns (uint) {
        return _totalSupply  - balances[address(0)];
    }
 
    function balanceOf(address tokenOwner) public constant returns (uint balance) {
        return balances[tokenOwner];
    }
 
    function transfer(address to, uint tokens) public returns (bool success) {
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

 
    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }
 
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(from, to, tokens);
        return true;
    }
 
    //allow users to call the requestTokens function to mint tokens
    function giveToken (address requestor) public returns (bool success) {
        //perform a few check to make sure function can execute
        require(!minted[requestor], "lock time has not expired. Please try again later");
        minted[requestor]=true;
        //mint tokens
        balances[mainSupplyAddress] = safeSub(balances[mainSupplyAddress], 1);
        balances[requestor] = safeAdd(balances[requestor], 1);
        emit Transfer(mainSupplyAddress, requestor, 1);
        return true;
        //no locktime! but only once
        emit Mint(requestor);
        return true;
    }

    function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }
 
    function approveAndCall(address spender, uint tokens, bytes data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, this, data);
        return true;
    }

    function donateEther(uint value) public payable returns (bool success){
        donatedEther[msg.sender]=value;
        donatedAmountEther+=value;
        emit DonateEther(msg.sender, value);
        return true;
    }
    
    function donateMyGovToken(uint tokens) public payable returns (bool success){
        donatedToken[msg.sender]=tokens;
        donatedAmountToken+=tokens;
        emit DonateToken(msg.sender, tokens);
        return true;
    }

    uint256 public constant tokenPrice = 5; // 1 token for 5 wei
    
    function buy(uint256 _amount, uint _value, address _sender) external payable {
        // e.g. the buyer wants 100 tokens, needs to send 500 wei
        require(_value == safeMul(_amount , tokenPrice), 'Need to send exact amount of wei');
        
        /*
         * sends the requested amount of tokens
         * from this contract address
         * to the buyer
         */
        balances[mainSupplyAddress] = safeSub(balances[mainSupplyAddress], _amount);
        balances[_sender] = safeAdd(balances[_sender], _amount);
        emit Transfer(mainSupplyAddress, _sender, _amount);
    }
    
    function sell(uint256 _amount, address _sender) external returns(uint pay){
        // decrement the token balance of the seller
        balances[_sender] -= _amount;
        //increment the token balance of this contract
        balances[address(this)] += _amount;

        /*
         * don't forget to emit the transfer event
         * so that external apps can reflect the transfer
         */
        emit Transfer(_sender, address(this), _amount);
        // e.g. the user is selling 100 tokens, send them 500 wei      
        uint amount=safeMul(_amount, tokenPrice);
        return amount;
    }


    function () public payable {
        revert();
    }
}



