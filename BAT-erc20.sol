pragma solidity ^0.5.12;

contract BAToken {
    string public constant name = "Basic Attention Token";
    string public constant symbol = "BAT";
    uint256 public constant decimals = 18;
    uint256 public totalSupply;

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

    address public ethFundDeposit;
    address public batFundDeposit;
    bool public isFinalized;
    uint256 public fundingStartBlock;
    uint256 public fundingEndBlock;
    uint256 public constant batFund = 500 * (10**6) * 10**decimals;
    uint256 public constant tokenExchangeRate = 6400; 
    uint256 public constant tokenCreationCap = 1500 * (10**6) * 10**decimals;
    uint256 public constant tokenCreationMin = 675 * (10**6) * 10**decimals;

    event LogRefund(address indexed _to, uint256 _value);
    event CreateBAT(address indexed _to, uint256 _value);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    constructor(
        address _ethFundDeposit,
        address _batFundDeposit,
        uint256 _fundingStartBlock,
        uint256 _fundingEndBlock
    ) public {
        isFinalized = false;
        ethFundDeposit = _ethFundDeposit;
        batFundDeposit = _batFundDeposit;
        fundingStartBlock = _fundingStartBlock;
        fundingEndBlock = _fundingEndBlock;
        totalSupply = batFund;
        balances[batFundDeposit] = batFund;
        emit CreateBAT(batFundDeposit, batFund);
    }

    function safeAdd(uint256 x, uint256 y) internal pure returns(uint256) {
        uint256 z = x + y;
        require((z >= x) && (z >= y));
        return z;
    }

    function safeSubtract(uint256 x, uint256 y) internal pure returns(uint256) {
        require(x >= y);
        uint256 z = x - y;
        return z;
    }

    function safeMult(uint256 x, uint256 y) internal pure returns(uint256) {
        uint256 z = x * y;
        require((x == 0) || (z / x == y));
        return z;
    }

    function createTokens() payable external {
        require(!isFinalized);
        require(block.number >= fundingStartBlock);
        require(block.number <= fundingEndBlock);
        require(msg.value > 0);

        uint256 tokens = safeMult(msg.value, tokenExchangeRate);
        uint256 checkedSupply = safeAdd(totalSupply, tokens);

        require(tokenCreationCap >= checkedSupply);

        totalSupply = checkedSupply;
        balances[msg.sender] = safeAdd(balances[msg.sender], tokens);
        emit CreateBAT(msg.sender, tokens);
    }

    function finalize() external {
        require(!isFinalized);
        require(msg.sender == ethFundDeposit);
        require(totalSupply >= tokenCreationMin);
        require(block.number > fundingEndBlock || totalSupply == tokenCreationCap);

        isFinalized = true;
        require(ethFundDeposit.send(address(this).balance));
    }

    function refund() external {
        require(!isFinalized);
        require(block.number > fundingEndBlock);
        require(totalSupply < tokenCreationMin);
        require(msg.sender != batFundDeposit);

        uint256 batVal = balances[msg.sender];
        require(batVal > 0);

        balances[msg.sender] = 0;
        totalSupply = safeSubtract(totalSupply, batVal);
        uint256 ethVal = batVal / tokenExchangeRate;
        emit LogRefund(msg.sender, ethVal);
        require(msg.sender.send(ethVal));
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value && _value > 0);
        balances[msg.sender] = safeSubtract(balances[msg.sender], _value);
        balances[_to] = safeAdd(balances[_to], _value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0);
        balances[_to] = safeAdd(balances[_to], _value);
        balances[_from] = safeSubtract(balances[_from], _value);
        allowed[_from][msg.sender] = safeSubtract(allowed[_from][msg.sender], _value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    mapping (address => mapping (address => uint256)) allowed;
}
