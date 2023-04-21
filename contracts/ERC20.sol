//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;
import "./IERC20.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 * which implements the Fungible ERC20 token.
*/

contract Coins is IERC20 {
    uint256 private tokenSupply = 1000 * (10**18);
    address private owner;
    string private tokenName;
    string private tokenSymbol;
    mapping(address => uint256) private tokenBalance;
    mapping(address => mapping(address => uint256)) private approvalBalance;

    /**
     * @dev Sets the values for name and symbol of the token.
     * All two of these values are immutable: they can only be set once during
     * construction.
     * @param _name is the name of token
     * @param _symbol is the symbol of token
     */
    constructor(string memory _name, string memory _symbol) {
        tokenName = _name;
        tokenSymbol = _symbol;
        owner = msg.sender;
        tokenBalance[owner] = tokenSupply;
    }

    /**
    * @dev this function sends token from msg.sender address to _to address with amount _amount
    * emits a transfer event.
    * @param _to is the address to which token is transferred.
    * @param _amount is the amount of token to be transferred.
    * @return boolean value.
    */
    function transfer(address _to, uint256 _amount) external returns (bool) {
        require(_to != address(0), "can not send tokens to zero address");
        require(tokenBalance[msg.sender] >= _amount, "Insufficient amount");
        tokenBalance[msg.sender] -= _amount;
        tokenBalance[_to] += _amount;
        emit Transfer(msg.sender, _to, _amount);
        return true;
    }

    /**
    * @dev this function creates new token and increases total supply, only deployer can do it,
    * emits a transfer event.
    * @param _account is the account in which token will be minted.
    * @param _amount is the amount of tokens to be minted.
    */
    function mint(address _account, uint256 _amount) external {
        require(msg.sender == owner, "not authorized to mint");
        require(
            _account != address(0),
            "Cannot mint tokens to the zero address"
        );
        tokenSupply += _amount;
        tokenBalance[_account] += _amount;
        emit Transfer(address(0), _account, _amount);
    }

    /**
    * @dev this function destroys token and decreases total supply, only deployer of token can do it,
    * emits a transfer event.
    * @param _account is the account from which token will be destroyed.
    * @param _amount is the amount of tokens to be burn.
    */
    function burn(address _account, uint256 _amount) external {
        require(msg.sender == owner, "not authorized to burn");
        require(tokenBalance[_account] >= _amount, "Not enough balance");
        tokenBalance[_account] -= _amount;
        tokenSupply -= _amount;
        emit Transfer(_account, address(0), _amount);
    }

    /**
    * @dev this function destroys token and decreases total supply, only the account which deployer approved can do it,
    * emits a transfer event.
    * @param _from is the account from which token will be destroyed
    * @param _amount is the amount of tokens to be burn
    */
    function burnFrom(address _from, uint256 _amount) external {
        require(approvalBalance[owner][msg.sender] >= _amount, "you are not approved or Low Approval Balance");
        require(_from != address(0), "can not burn from zero address");
        require(tokenBalance[_from] >= _amount, "Insufficient funds in from account");
        approvalBalance[owner][msg.sender] -= _amount;
        tokenBalance[_from] -= _amount;
        tokenSupply -= _amount;
        emit Transfer(_from, address(0), _amount);
    }

    /**
    * @dev this function approves another account to use their token, msg.sender will call this function,
    * emits a approve event.
    * @param _spender is the account which will be approved.
    * @param _amount is the amount of tokens which will be approved.
    * @return boolean value.
    */
    function approve(address _spender, uint256 _amount) external returns (bool) {
        require(msg.sender != _spender, "Can not approve Yourself");
        approvalBalance[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }

    /**
    * @dev this function transfers token from owner account to another acoount, only approved accounts can use this function,
    * emits a transfer event.
    * @param _from is the account from which tokens will be transferred.
    * @param _to is the account to which tokens will be transferred.
    * @param _amount is the amount of tokens which will be transferred.
    * @return boolean value.
    */
    function transferFrom(
        address _from,
        address _to,
        uint256 _amount
    ) external returns (bool) {
        require(_from != address(0) && _to != address(0), "can not transfer or send to zero address");
        require(
            tokenBalance[_from] >= _amount,
            "from does not have sufficient balance"
        );
        require(
            approvalBalance[_from][msg.sender] >= _amount,
            "Not Authorized Or Insufficient Balance"
        );
        approvalBalance[_from][msg.sender] -= _amount;
        tokenBalance[_from] -= _amount;
        tokenBalance[_to] += _amount;
        emit Transfer(_from, _to, _amount);
        return true;
    }

    /**
    * @dev gives information of total supply of tokens.
    * @return tokenSuppy i.e. total supply.
    */
    function totalSupply() external view returns (uint256) {
        return tokenSupply;
    }

    /**
    * @dev gives information about the number of tokens of an address.
    * @param _account of which tokens to be find.
    * @return balance of token in that account.
    */
    function balanceOf(address _account) external view returns (uint256) {
        return tokenBalance[_account];
    }

    /**
    * @dev gives information about the tokens that are on approved to an account.
    * @param _owner is the account of owner.
    * @param _spender is the account which is approved.
    * @return number of tokens which are approved.
    */
    function allowance(
        address _owner,
        address _spender
    ) external view returns (uint256) {
        return approvalBalance[_owner][_spender];
    }

    /**
    * @dev this function is used to get name of token.
    * @return name of token.
    */
    function name() external view returns (string memory) {
        return tokenName;
    }

    /**
    * @dev this function is used to get symbol of token.
    * @return symbol of token.
    */
    function symbol() external view returns (string memory) {
        return tokenSymbol;
    }
}