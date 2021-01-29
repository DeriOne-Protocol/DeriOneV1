// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./interfaces/IETHOptionHegicV888.sol";
import "./interfaces/IETHPoolHegicV888.sol";
import "./libraries/DataTypes.sol";

contract DeriOneV1HegicV888 is Ownable {
    using SafeMath for uint256;

    IETHOptionHegicV888 private ETHOptionHegicV888;
    IETHPoolHegicV888 private ETHPoolHegicV888;

    struct OptionHegicV888 {
        DataTypes.UnderlyingAsset underlyingAsset;
        DataTypes.OptionType optionType;
        uint256 expiry;
        uint256 strikeUSD;
        uint256 premiumWEI;
    }

    constructor(
        address _hegicETHOptionV888Address,
        address _hegicV888ETHPoolAddress
    ) public {
        instantiateETHOptionHegicV888(_hegicETHOptionV888Address);
        instantiateETHPoolHegicV888(_hegicV888ETHPoolAddress);
    }

    /// @param _hegicETHOptionV888Address HegicETHOptionV888Address
    function instantiateETHOptionHegicV888(address _hegicETHOptionV888Address)
        public
        onlyOwner
    {
        ETHOptionHegicV888 = IETHOptionHegicV888(_hegicETHOptionV888Address);
    }

    /// @param _hegicV888ETHPoolAddress HegicETHPoolV888Address
    function instantiateETHPoolHegicV888(address _hegicV888ETHPoolAddress)
        public
        onlyOwner
    {
        ETHPoolHegicV888 = IETHPoolHegicV888(_hegicV888ETHPoolAddress);
    }

    /// @param _sizeWEI the size of an option to buy in WEI
    function hasEnoughETHLiquidityHegicV888(uint256 _sizeWEI)
        internal
        view
        returns (bool)
    {
        // `(Total ETH in contract) * 0.8 - the amount utilized for options`
        // we might or might not need the *0.8 part
        uint256 availableBalance =
            ETHPoolHegicV888.totalBalance().mul(8).div(10);
        uint256 amountUtilized =
            ETHPoolHegicV888.totalBalance().sub(
                ETHPoolHegicV888.availableBalance()
            );

        require(
            availableBalance > amountUtilized,
            "there is not enough available balance"
        );
        uint256 maxSize = availableBalance.sub(amountUtilized);

        // what happens when the value of a uint256 is negative?
        // is this equation right?
        if (maxSize > _sizeWEI) {
            return true;
        } else if (maxSize <= _sizeWEI) {
            return false;
        }
    }

    /// @notice calculate and return the ETH put option in Hegic v888
    /// @param _expiry expiration date in seconds from now
    /// @param _strikeUSD strike price in USD with 8 decimals
    /// @param _sizeWEI option size in WEI
    function getETHPutHegicV888(
        uint256 _expiry,
        uint256 _strikeUSD,
        uint256 _sizeWEI
    ) internal view returns (OptionHegicV888 memory) {
        IETHOptionHegicV888.OptionType optionType =
            IETHOptionHegicV888.OptionType.Put;
        (uint256 minimumPremiumToPayWEI, , , ) =
            ETHOptionHegicV888.fees(
                _expiry,
                _sizeWEI,
                _strikeUSD,
                uint8(optionType)
            );

        OptionHegicV888 memory ETHPut =
            OptionHegicV888(
                DataTypes.UnderlyingAsset.ETH,
                DataTypes.OptionType.Put,
                _expiry,
                _strikeUSD,
                minimumPremiumToPayWEI
            );
        return ETHPut;
    }
}

// you need to use require for strike price and expiry and possibly in other places
// the hegic has some require
// https://github.com/hegic/contracts-v888/blob/ecdc7816c1deef8d2e3cf2629c68807ffdef2cc5/contracts/Options/HegicETHOptions.sol#L121
