// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {SimpleStorage} from "./simpleStorage.sol";
contract AddFiveStorage is SimpleStorage{
    //+5
    //overrides
    function store(uint256 _NewNumber) public override{
        myFavoriteNumber=_NewNumber+5;
    }
}
