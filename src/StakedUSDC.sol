//SPDX-License-Identifier: MIT

// Disclaimer

/** @dev This contract is freelance project which i am doing, not a production ready code because we are working on it. It may have bugs.
    This contract doesn't use upgradablity functionalities which are important for a vault contract, 
    but not included in the scope of project.
*/ 

pragma solidity ^0.8.18;

import {ERC4626} from "lib/openzeppelin-contracts/contracts/token/ERC20/extensions/ERC4626.sol";
import {ERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {ReentrancyGuard} from "lib/openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";
import {SafeERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

contract StakedUSDC is ERC4626, ReentrancyGuard {
    using SafeERC20 for IERC20;

    uint256 private constant BPS = 10_000;

    error InvalidAmount();
    error InvalidTokenAddress();
    error depositPaused();
    error InvalidCaller();
    error AlreadyClaimed();
    error WithdrawalPeriodNotPassed();

    event deposited(uint256 indexed amount, address user);
    event DepositPaused(bool Paused);
    event NewAdmin(address admin);
    event NewManager(address Manager);
    event Withdraw(address caller, address receiver, address owner, assets);
    event FundsAreNotAvailableCurrently_PleaseTryAgainLater(uint totalAvailableForWithdrawals);

    // modifiers
    modifier onlyManager {
        if(msg.sender != $.managerRole) revert InvalidCaller();
        _;
    }

    modifier onlyAdmin {
        if(msg.sender != $.admin) revert InvalidCaller();
        _;
    }

    // STORAGE VARIABLES
    struct Storage{
        IERC20 asset;
        address admin;
        address managerRole;
        uint256 withdrawalPeriod;
        uint256 withdrawalCounter;
        bool depositPaused;
        uint256 totalPendingWithdrawals;
        uint256 totalAvailableForWithdrawals; 
        mapping (uint256 => RequestForWithdrawals) RequestsForWithdraw;
        uint256 totalAllocated;
        Allocation[] allocations;
        mapping(address => bool) isAdapter;
    }

    struct RequestForWithdrawals {
        address user;
        uint256 amounts;
        uint256 withdrawalTimestamp;
        bool claimed;
    }

    struct Allocation {
        address protocol;
        uint256 targetBps; // BasisPoint
    }

    bytes32 private constant STORAGE_LOCATION = keccak256(abi.encode(uint256(keccak256("StakedUSDCStorageLocation")) -1));

    function _getStorage() private pure returns (Storage storage $) {
        bytes32 position = STORAGE_LOCATION;
        assembly {
            $.slot := position
        }
    }

    //CONSTRUCTORS

    
    constructor(IERC20 _asset, address _admin, address _managerRole) ERC20("StakedUSDC", "sUSDC") ERC4626(_asset) {
        Storage $ = _getStorage();
        $.asset = IERC20(_asset);
        $.admin = _admin;
        $.managerRole = _managerRole;
        
        $.withdrawalPeriod = 15 days;
    }


    //SETTERS
    function setDepositPaused(bool paused) external onlyManager {
        Storage storage $ = _getStorage();
        $.depositPaused = paused;
        emit DepositPaused(Paused);
    }

    function setAdmin(address _admin) external onlyAdmin{
        require(_admin != address(0), "ZeroAddress");
        Storage storage $ = _getStorage();
        $.admin = _admin;
        emit NewAdmin(_admin);
    }

    function addAdapter(address adapter) external onlyAdmin {
        Storage storage $ = _getStorage();

        require(adapter != address(0), "Zero adapter");
        require(
            IProtocolAdapter(adapter).asset() == address($.asset),
            "Wrong asset"
        );

        $.isAdapter[adapter] = true;
    }

    function setManager(address _manager) external onlyAdmin{
        require(_manager != address(0), "ZeroAddress");
        Storage storage $ = _getStorage();
        $.managerRole = _manager;
        emit NewManager(_manager);
    }


    // EXERNAL FUNCTIONS
    function _deposit(address caller, address receiver, uint256 assets, uint256 shares) internal nonReentrant override {
        Storage storage $ = _getStorage();

        if (assets == 0 || shares == 0) revert InvalidAmount();

        if($.depositPaused) revert depositPaused();

        super._deposit(caller, receiver, assets, shares);

        emit deposited(Amount, msg.sender);
    }

    function _withdraw(address caller, address receiver,address owner, uint256 assets, uint256 shares) internal nonReentrant override {
        if (caller != owner) _spendAllowance(owner, caller, shares);

        _burn(owner, shares);

        Storage storage $ = _getStorage();

        if($.totalAvailableForWithdrawals >= assets){
            IERC20($.assets).safeTransferFrom(address(this), receiver, assets);
            emit Withdraw(caller, receiver, owner, assets);
            return; 
        }

        $.totalPendingWithdrawals += assets;
        $.RequestsForWithdraw[$.withdrawalCounter] = RequestForWithdrawals({user: receiver, amounts: assets, withdrawalTimestamp: block.timestamp, claimed: false});

        emit WithdrawalRequested(caller, receiver, reciever, assets, withdrawalCounter);
        
        $.withdrawalCounter++;
    }

    function claimWithdraw(uint256 withdrawalID) external nonreentrant {
        Storage storage $ = _getStorage();

        if($.RequestsForWithdraw[withdrawalID].claimed) revert AlreadyClaimed();

        // @note MANDATORY PERIOD FOR EVERYONE SO THAT MANAGER HAVE TIME TO MANAGE FUNDS FROM DIFFERENT STRATEGIES;
        if($.RequestsForWithdraw[withdrawalID].withdrawalTimestamp + $.withdrawalPeriod > block.timestamp){
            revert WithdrawalPeriodNotPassed();
        }

        if($.totalAvailableForWithdrawals > $.RequestsForWithdraw[withdrawalID].amounts){
            $.assets.transferFrom(address(this), $.RequestsForWithdraw[withdrawalID].user, $.RequestsForWithdraw[withdrawalID].amounts);
            
            $.totalPendingWithdrawals -= $.RequestsForWithdraw[withdrawalID].amounts;
            $.totalAvailableForWithdrawals -= $.RequestsForWithdraw[withdrawalID].amounts;
            $.RequestsForWithdraw[withdrawalID].claimed = true;
            
            emit WithdrawClaimed(withdrawalID, $.RequestsForWithdraw[withdrawalID].amounts);
        }
        else{
            emit FundsAreNotAvailableCurrently_PleaseTryAgainLater($.totalAvailableForWithdrawals);
        }
    }


    // it decides what the pending and available amount for withdrawals are.
    function _MatchWithdrawal() private {
        Storage storage $ = _getStorage();
        uint256 balanceOfUSDC = $.asset.balanceOf(address(this));

        if(balanceOfUSDC > $.totalAvailableForWithdrawals){
            if(balanceOfUSDC <= $.totalPendingWithdrawals){
                $.totalAvailableForWithdrawals = balanceOfUSDC;
            }
            else{
                $.totalAvailableForWithdrawals = $.totalPendingWithdrawals;
            }
        }
    }

  // total assets of this protocol
    function totalAssets() public view override returns (uint256 netProtocolAssets) {
        Storage storage $ = _getStorage();

        uint256 sum;
        for (uint256 i = 0; i < $.allocations.length; ++i) {
            address protocol = $.allocations[i].protocol;
            if (protocol == address(0)) continue;
            // safe external call to adapter's totalAssets()
            sum += IProtocolAdapter(protocol).totalAssets();
        }

        grossProtocolAssets = sum;

        if (sum > $.totalAvailableForWithdrawals) {
            netProtocolAssets = sum - $.totalAvailableForWithdrawals;
        } else {
            netProtocolAssets = 0;
        }
    }

    function _totalManagedAssets() internal view returns (uint256 total) {
        Storage storage $ = _getStorage();

        total += $.asset.balanceOf(address(this));

        for (uint256 i; i < $.allocations.length; i++) {
            total += IProtocolAdapter($.allocations[i].protocol).totalAssets();
        }

        total -= $.totalAvailableForWithdrawals;
}

    function rebalance() external nonReentrant onlyManager {
        Storage storage $ = _getStorage();

        _MatchWithdrawal();

        uint256 totalAssetsManaged = _totalManagedAssets();

        for (uint256 i; i < $.allocations.length; i++) {
            Allocation memory alloc = $.allocations[i];
            IProtocolAdapter adapter = IProtocolAdapter(alloc.protocol);

            uint256 targetValue =
                (totalAssetsManaged * alloc.targetBps) / BPS;

            uint256 currentValue = adapter.totalAssets();

            if (currentValue > targetValue) {
                adapter.withdraw(currentValue - targetValue);
            }
        }

        for (uint256 i; i < $.allocations.length; i++) {
            Allocation memory alloc = $.allocations[i];
            IProtocolAdapter adapter = IProtocolAdapter(alloc.protocol);

            uint256 targetValue =
                (totalAssetsManaged * alloc.targetBps) / BPS;

            uint256 currentValue = adapter.totalAssets();

            if (currentValue < targetValue) {
                uint256 amount = targetValue - currentValue;
                // Move funds to adapter
                $.asset.transfer(alloc.protocol, deficit);

                // Adapter deposits into protocol
                adapter.deposit(deficit);
            }
        }
}

    function setAllocations(Allocation[] calldata allocations) external nonReentrant onlyManager {
        Storage storage $ = _getStorage();

        uint256 totalBps;
        uint256 length = allocations.length;
        require(length >= 2, "At Least 2 protocols");
        // delete previosu allocations
        delete $.allocations;

        for(uint256 i = 0; i<length; ++i){
            address protocol = allocations[i].protocol;
            uint256 targetBps = allocations[i].targetBps;
            require($.isAdapter[protocol], "Adapter not allowed");

            totalBps += targetBps;
            $.allocations.push(allocations[i]);
        }
        require(totalBps == $.BPS, "BPS is not 100%");
    }

}
