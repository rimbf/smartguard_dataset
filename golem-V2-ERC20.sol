


contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;


    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

   
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

   
    function transfer(address recipient, uint256 amount) public returns (bool) {
             require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        require(_balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance")) check_balance;
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount) transfer_event;
        return true;
    }

  
   
}





