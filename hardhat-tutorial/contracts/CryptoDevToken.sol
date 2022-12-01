// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./ICryptoDevs.sol";

contract CryptoDevToken is ERC20, Ownable {

    uint256 public constant tokenPrice = 0.001 ether;
    uint256 public constant tokensPerNFT = 10 * 10**18;
    uint256 public constant maxTotalSupply = 10000 * 10**18;
    
    ICryptoDevs CryptoDevsNFT; // object of Crytodevs nft contract which is an interface

    mapping(uint256 => bool) public tokenIdsClaimed; // if someone owns an NFT then they can claim 10 tokens 

    constructor(address _cryptoDevsContract) ERC20("Crypto Dev Token", "CD") {
        CryptoDevsNFT = ICryptoDevs(_cryptoDevsContract);
    }

    function mint(uint256 amount) public payable {

        uint256 _requiredAmount = amount * tokenPrice;
        // the eth sent by the caller in msg.sender should be atleast the _requiredAmount
        require(msg.value >= _requiredAmount, "Eth sent is incorrect, you have sent less value than required!");

        uint256 amountWithDecimals = amount * 10**18;
        // we should not exceed the minting of tokens ahead of maxTotalSupply
        // totalSupply() is a ERC-20 function which Returns the amount of tokens in existence.
        require((totalSupply() + amountWithDecimals) <= maxTotalSupply, "Exceeds maximum total supply available.");

        // _mint is ERC-20 function which mints the given amount of token to the msg.sender address
        _mint(msg.sender, amountWithDecimals);
    }

    // if someone has a CryptoDevs NFT they can claim upto 10 tokens, but they need to give the gas fees for that
    // will not work when: 1) user has no cryptodev nft 2) user has already claimed all the tokens corresponding to their nfts
    function claim() public {
        address sender = msg.sender;
        // get the number of nft tokens held by the sender
        uint256 balance = CryptoDevsNFT.balanceOf(sender);
        require(balance > 0, "You do not own any CryptoDevs NFT");

        uint256 amount = 0; // keeps track of unclaimed tokenIds

        for (uint256 i = 0; i < balance; i++) {
            uint256 tokenId = CryptoDevsNFT.tokenOfOwnerByIndex(sender, i);
            if (!tokenIdsClaimed[tokenId]) {
                amount += 1;
                tokenIdsClaimed[tokenId] = true;
            }
        }

        // if user has already claimed, he cant do it again.
        require(amount > 0, "You have already claimed all the tokens");

        _mint(msg.sender, amount * tokensPerNFT);

    }

    function withdraw() public onlyOwner {
        uint256 amount = address(this).balance;
        require(amount > 0, "No balance left to withdraw");

        address _owner = owner();
        (bool sent, ) = _owner.call{value: amount}("");
        require(sent, "Failed to send Ether");
    }

    // these functions help the smart contract receive eth
    receive() external payable {}

    fallback() external payable {}

}