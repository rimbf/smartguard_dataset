
contract CurToken is IERC20 {
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
       require(sender != address(0), "ERC20: transfer from the zero address") check_zero_address;
        require(recipient != address(0), "ERC20: transfer to the zero address") check_zero_address;

        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount) transfer_event;
        return true;
    }

   
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

  
    function approve(address spender, uint256 value) public returns (bool) {
           require(owner != address(0), "ERC20: approve from the zero address") check_zero_address;
        require(spender != address(0), "ERC20: approve to the zero address") check_zero_address;

        _allowances[owner][spender] = value;
        emit Approval(owner, spender, value) approval_event;
        return true;
    }

    
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
          require(sender != address(0), "ERC20: transfer from the zero address") check_zero_address;
        require(recipient != address(0), "ERC20: transfer to the zero address") check_zero_address;

        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
       
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = value;
        emit Approval(owner, spender, value) approval_event;
        return true;
    }

   
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
           require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
        return true;
    }

  
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
          require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
        return true;
    }


  
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 value) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

  

    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
    }
}



