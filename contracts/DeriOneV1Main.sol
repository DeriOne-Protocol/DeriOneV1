// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "./DeriOneV1CharmV02.sol";
import "./DeriOneV1HegicV888.sol";
import "./libraries/DataTypes.sol";

/// @author tai
/// @notice For now, this contract gets the cheapest ETH/WETH put options price from Opyn V1 and Hegic V888
/// @dev explicitly state the data location for all variables of struct, array or mapping types (including function parameters)
/// @dev adjust visibility of variables. they should be all private by default i guess
contract DeriOneV1Main is DeriOneV1CharmV02, DeriOneV1HegicV888 {
    using SafeMath for uint256;

    constructor(
        address _charmV02OptionFactoryAddress,
        address _hegicETHOptionV888Address,
        address _hegicV888ETHPoolAddress
    )
        public
        DeriOneV1CharmV02(_charmV02OptionFactoryAddress)
        DeriOneV1HegicV888(_hegicETHOptionV888Address, _hegicV888ETHPoolAddress)
    {}


    /// @param _expiryTimestamp expiration date in unix timestamp
    /// @param _strikeUSD strike price in USD with 8 decimals
    /// @param _optionType option type
    /// @param _sizeWEI option size in WEI
    function getETHOptionListFromExactValues(
        uint256 _expiryTimestamp,
        uint256 _strikeUSD,
        DataTypes.OptionType _optionType,
        uint256 _sizeWEI
    ) public view returns (DataTypes.Option[] memory) {
        require((_expiryTimestamp > block.timestamp), "expiration date has to be some time in the future");

        uint256 expirySecondsFromNow = _expiryTimestamp.sub(block.timestamp);

        DataTypes.Option memory ETHOptionHegicV888 =
            getETHOptionFromExactValuesHegicV888(expirySecondsFromNow, _strikeUSD, _optionType, _sizeWEI);
        require(
            hasEnoughETHLiquidityHegicV888(_sizeWEI) == true,
            "your size is too big for liquidity in the Hegic V888"
        );

        DataTypes.Option memory ETHOptionCharmV02 =
            getETHOptionFromExactValuesCharmV02(_expiryTimestamp, _strikeUSD, _optionType, _sizeWEI);
        require(
            hasEnoughETHLiquidityCharmV02(_sizeWEI) == true,
            "your size is too big for liquidity in the Charm V02"
        );

        DataTypes.Option[] memory ETHOptionList;
        if(ETHOptionCharmV02.protocol == DataTypes.Protocol.Invalid) {
            ETHOptionList = new DataTypes.Option[](1);
            ETHOptionList[0] = ETHOptionHegicV888;
        } else {
            ETHOptionList = new DataTypes.Option[](2);
            ETHOptionList[0] = ETHOptionHegicV888;
            ETHOptionList[1] = ETHOptionCharmV02;
        }

        return ETHOptionList;
    }
}
