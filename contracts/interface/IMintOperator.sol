// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMintOperator {
    function mintByOperator(uint256 _amount) external;
}