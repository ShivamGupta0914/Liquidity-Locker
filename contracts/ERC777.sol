//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./IERC777.sol";

contract Coins2 is IERC777 {
    uint256 _totalSupply;
    address[] private _defaultOperatorsArray;
    string _name;
    string _symbol;
    mapping(address => uint256) balances;
    mapping(address => mapping(address => bool)) private _operators;
    mapping(address => mapping(address => uint256)) private _allowances;

    constructor(
        string memory nameOfToken,
        string memory symbolOfToken,
        uint256 _initialSupply
    ) {
        _name = nameOfToken;
        _symbol = symbolOfToken;
        _totalSupply = _initialSupply;
        balances[msg.sender] = _initialSupply;
    }

    function authorizeOperator(address operator) external {
        _operators[msg.sender][operator] = true;
    }

    function revokeOperator(address operator) external {
        _operators[msg.sender][operator] = false;
    }

    function send(
        address recipient,
        uint256 amount,
        bytes memory data
    ) external {
        require(balances[msg.sender] >= amount, "not enough balance");
        balances[msg.sender] -= amount;
        balances[recipient] += amount;
    }

    function operatorSend(
        address from,
        address to,
        uint256 amount,
        bytes calldata data,
        bytes calldata operatorData
    ) external {
        require(_operators[from][msg.sender] == true, "not authorized to send");
        require(balances[from] >= amount, "not enough balance");
        balances[from] -= amount;
        balances[to] += amount;
    }

    function mint(uint256 amount) external {
        balances[msg.sender] += amount;
    }

    function name() external view returns (string memory) {
        return _name;
    }

    function burn(uint256 amount, bytes calldata data) external {}

    function operatorBurn(
        address from,
        uint256 amount,
        bytes calldata data,
        bytes calldata operatorData
    ) external {}

    function symbol() external view returns (string memory) {
        return _symbol;
    }

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address holder) external view returns (uint256) {
        return balances[holder];
    }

    function granularity() external pure returns (uint256) {
        return 1;
    }

    function defaultOperators() external view returns (address[] memory) {
        return _defaultOperatorsArray;
    }

    function isOperatorFor(
        address operator,
        address holder
    ) external view returns (bool) {
        return _operators[holder][operator];
    }
}
