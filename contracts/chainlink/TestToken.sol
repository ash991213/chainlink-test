// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../interface/IMintOperator.sol";

contract TestToken is ERC20, Ownable, IMintOperator {

    mapping(address => bool) public operatorList;
    mapping(address => bool) public whiteList;

    constructor(string memory _name, string memory _symbol) ERC20(_name, _symbol) {
    }

    function mintByOperator(uint256 _amount) external override {
        require(operatorList[msg.sender], "not operator");
        super._mint(address(this), _amount);
    }

    function claimToken(uint256 _amount) external {
        require(whiteList[msg.sender], "not in whitelist");
        IERC20(this).transfer(msg.sender, _amount);
    }

    function addOperator(address _operator) external onlyOwner {
        operatorList[_operator] = true;
    }

    function removeOperator(address _operator) external onlyOwner {
        operatorList[_operator] = false;
    }

    function addWhiteList(address _operator) external onlyOwner {
        whiteList[_operator] = true;
    }

    function removeWhiteList(address _operator) external onlyOwner {
        whiteList[_operator] = false;
    }
}
