// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@aave/core-v3/contracts/interfaces/IPool.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IProtocolAdapter} from "./IProtocolAdapter.sol";

contract AaveV3Adapter is IProtocolAdapter {
    IPool public immutable pool;
    IERC20 public immutable assetToken;
    IERC20 public immutable aToken;
    address public immutable vault;

    modifier onlyVault() {
        require(msg.sender == vault, "Not vault");
        _;
    }

    constructor(
        address _vault,
        address _pool,
        address _asset,
        address _aToken
    ) {
        vault = _vault;
        pool = IPool(_pool);
        assetToken = IERC20(_asset);
        aToken = IERC20(_aToken);

        // Approve infinite transfers into Aave pool
        assetToken.approve(address(pool), type(uint256).max);
    }

    function asset() external view override returns (address) {
        return address(assetToken);
    }

    function totalAssets() external view override returns (uint256) {
        return aToken.balanceOf(address(this));
    }

    function deposit(uint256 amount) external override onlyVault {
        require(amount > 0, "0 amount");
        pool.supply(address(assetToken), amount, address(this), 0);
    }

    function withdraw(uint256 amount) external override onlyVault {
        require(amount > 0, "0 amount");
        // Aave returns exactly amount requested
        pool.withdraw(address(assetToken), amount, address(this));
        IERC20(assetToken).transfer(vault, amount);
    }
}