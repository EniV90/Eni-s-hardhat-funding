// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "./PriceConverter.sol";
// Get funds from users
//Withdraw funds
// Set a minimum funding value in USD

// const
// immutable

error FundMe__NotOwner();

/**
 * @title Acontract for Crowd funding
 * @author Victor Eni
 * @notice This contract is to demo a sample funding contract
 * @dev This implements pricefeeds as library
 */

contract FundMe {
    // Type Declaration
    using PriceConverter for uint256;

    //State Variables
    uint256 public constant MINIMUM_USD = 50 * 1e18;

    address[] public s_funders;
    mapping(address => uint256) public s_addressToAmountFunded;

    address public immutable i_owner;

    AggregatorV3Interface public s_priceFeed;

    constructor(address priceFeedAddress) {
        i_owner = msg.sender;

        s_priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    modifier onlyOwner() {
        //  require(msg.sender == i_owner, "Sender not owner!");
        if (msg.sender != i_owner) {
            revert FundMe__NotOwner();
        }
        _;
    }

    function fund() public payable {
        // want to be able to set a minimum fund amount in USD
        // 1. How to send ETH to the Contract?
        require(
            msg.value.getConversionRate(s_priceFeed) >= MINIMUM_USD,
            "Didn't send enough"
        ); // 1e18 == 1 * 10 ** 18 == 1000000000000000000
        s_funders.push(msg.sender);
        s_addressToAmountFunded[msg.sender] = msg.value;
    }

    function withdraw() public onlyOwner {
        for (
            uint256 funderIndex = 0;
            funderIndex < s_funders.length;
            funderIndex++
        ) {
            address funder = s_funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        //reset the array
        s_funders = new address[](0);
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "call Failed");
    }

    function cheaperWithdraw() public payable onlyOwner {
        address[] memory funders = s_funders;
        //mappings cant be in memory
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        s_funders = new address[](0);
        (bool success, ) = i_owner.call{value: address(this).balance}("");
        require(success);
    }

    // what happens when someone sends this contract ETH without calling fund function?

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }

    
}
// withdraw the funds
// three different way
//transfer
//send
//call
//1. Transfer

//msg.sender = address
//payable(msg.sender) = payable address
// payable(msg.sender).transfer(address(this).balance);
//   }
// 2. send
//    bool sendSuccess = payable(msg.sender).send(address(this).balance);
//    require(sendSuccess, "Send Failed");

//3. call
//   (bool callSuccess, ) = payable(msg.sender).call{value:address(this).balance("");
//   require(callSucess, "call Failed");
//   }
// }
