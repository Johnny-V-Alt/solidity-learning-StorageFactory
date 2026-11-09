// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {SimpleStorage} from "./simpleStorage.sol";
contract StorageFactory{

    SimpleStorage[] public listOfmystorageContracts;
    function CreateSimpleStorageFactory() public {
        SimpleStorage newStorage=new SimpleStorage();
        listOfmystorageContracts.push(newStorage);
    }

    function sfstore(uint256 _simpleStorageIndex,uint256 _simpleStorageNumber) public {
        //Address
        //ABI -Appliction Binary Interface
        SimpleStorage mySimpleStorage=listOfmystorageContracts[_simpleStorageIndex];
        mySimpleStorage.store(_simpleStorageNumber);
    }

    function sfGet(uint256 _simpleStorageIndex) public view returns(uint256){
        SimpleStorage mySimpleStorage=listOfmystorageContracts[_simpleStorageIndex];
        return mySimpleStorage.retrieve();
    }

    
}
