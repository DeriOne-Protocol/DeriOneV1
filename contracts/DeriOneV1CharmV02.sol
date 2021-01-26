// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/ICharmV02OptionFactory.sol";
import "./interfaces/ICharmV02OptionMarket.sol";
import "./libraries/DataTypes.sol";

contract DeriOneV1CharmV02 is Ownable {
    ICharmV02OptionFactory private CharmV02OptionFactoryInstance;

    struct OptionCharmV02 {
        DataTypes.UnderlyingAsset underlyingAsset;
        DataTypes.OptionType optionType;
        uint256 expiry;
        uint256 strikeUSD;
        uint256 premiumWEI;
    }
    constructor(address _charmV02OptionFactoryAddress) public {
        instantiateCharmV02OptionFactory(_charmV02OptionFactoryAddress);
    }

    /// @param _charmV02OptionFactoryAddress CharmV02 OptionFactoryAddress
    function instantiateCharmV02OptionFactory(
        address _charmV02OptionFactoryAddress
    ) public onlyOwner {
        CharmV02OptionFactoryInstance = ICharmV02OptionFactory(
            _charmV02OptionFactoryAddress
        );
    }

    function _getCharmV02OptionMarketAddressList()
        private
        view
        returns (address[] memory)
    {
        uint256 marketsCount = CharmV02OptionFactoryInstance.numMarkets();
        address[] memory CharmV02OptionMarketAddressList =
            new address[](marketsCount);
        for (uint256 i = 0; i < marketsCount; i++)
            CharmV02OptionMarketAddressList[i] = CharmV02OptionFactoryInstance
                .markets(i);
        return CharmV02OptionMarketAddressList;
    }

    /// @param _charmV02OptionMarketAddressList CharmV02 OptionMarketAddressList
    function _getCharmV02OptionMarketInstanceList(
        address[] memory _charmV02OptionMarketAddressList
    ) private pure returns (ICharmV02OptionMarket[] memory) {
        ICharmV02OptionMarket[] memory charmV02OptionMarketInstanceList =
            new ICharmV02OptionMarket[](
                _charmV02OptionMarketAddressList.length
            );
        for (uint256 i = 0; i < _charmV02OptionMarketAddressList.length; i++) {
            charmV02OptionMarketInstanceList[i] = ICharmV02OptionMarket(
                _charmV02OptionMarketAddressList[i]
            );
        }
        return charmV02OptionMarketInstanceList;
    }

}
