

contract Token {

        address public owner;
        address public config;
        bool public locked;
        address public dao;
        address public badgeLedger;
        uint256 public totalSupply;

        mapping(address => uint256) balances;
        mapping(address => mapping(address => uint256)) allowed;
        mapping(address => bool) seller;

        /// @return total amount of tokens

        modifier ifSales() {
                if (!seller[msg.sender]) throw;
                _
        }

        modifier ifOwner() {
                if (msg.sender != owner) throw;
                _
        }

        modifier ifDao() {
                if (msg.sender != dao) throw;
                _
        }

        event Transfer(address indexed _from, address indexed _to, uint256 _value);
        event Mint(address indexed _recipient, uint256 _amount);
        event Approval(address indexed _owner, address indexed _spender, uint256 _value);

       

        function balanceOf(address _owner) constant returns(uint256 balance) {
                return balances[_owner];
        }

        function transfer(address _to, uint256 _value) returns(bool success) {
                if (balances[msg.sender] >= _value && _value > 0) check_balance {
                        balances[msg.sender] = subtractSafely(balances[msg.sender], _value);
                        balances[_to] = addSafely(balances[_to], _value);
                        emit Transfer(msg.sender, _to, _value) transfer_event;
                        success = true;
                } else {
                        success = false;
                }
                return success;
        }

        function transferFrom(address _from, address _to, uint256 _value) returns(bool success) {
                if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
                        balances[_to] = addSafely(balances[_to], _value);
                        balances[_from] = subtractSafely(balances[_from], _value);
                        require (allowed[_from][msg.sender] = subtractSafely(allowed[_from][msg.sender], _value)) check_sender_authorization;
                        emit Transfer(_from, _to, _value) transferFrom_event;
                        return true;
                } else {
                        return false;
                }
        }

        function approve(address _spender, uint256 _value) returns(bool success) {
                allowed[msg.sender][_spender] = _value;
                Approval(msg.sender, _spender, _value) approval_event;
                success = true;
                return success;
        }

        function allowance(address _owner, address _spender) constant returns(uint256 remaining) {
                remaining = allowed[_owner][_spender];
                return remaining;
        }

        function mint(address _owner, uint256 _amount) ifSales returns(bool success) {
                totalSupply = addSafely(_amount, totalSupply);
                balances[_owner] = addSafely(balances[_owner], _amount);
                return true;
        }

       

}