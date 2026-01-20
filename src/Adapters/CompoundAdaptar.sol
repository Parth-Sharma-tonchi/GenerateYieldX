//SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {IProtocolAdapter} from "../IProtocolAdapter.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@compound-finance/comet/contracts/interfaces/IComet.sol";

contract CompoundV3Adapter is IProtocolAdapter {
    IComet public immutable comet;
    IERC20 public immutable asset; // USDC
    address public immutable vault;

    modifier onlyVault() {
        require(msg.sender == vault, "Not vault");
        _;
    }

    constructor(
        address _vault,
        address _comet,
        address _asset
    ) {
        vault = _vault;
        comet = IComet(_comet);
        asset = IERC20(_asset);

        // Infinite approval to Comet
        asset.approve(_comet, type(uint256).max);
    }

    // ============================
    // IProtocolAdapter
    // ============================

    function asset() external view returns (address) {
        return address(asset);
    }

    /// @notice Returns USDC-equivalent value of THIS adapter's position
    function totalAssets() external view returns (uint256) {
        return comet.balanceOf(address(this));
    }

    /// @notice Adapter must already hold USDC
    function deposit(uint256 amount) external onlyVault {
        comet.supply(address(asset), amount);
    }

    /// @notice Withdraw USDC and send back to vault
    function withdraw(uint256 amount) external onlyVault {
        comet.withdraw(address(asset), amount);
        asset.transfer(vault, amount);
    }
}