//SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;


interface IProtocolAdapter {
    function asset() external view returns (address);

    function totalAssets() external view returns (uint256);

    function deposit(uint256 amount) external;

    function withdraw(uint256 amount) external;
}