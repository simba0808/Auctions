//SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface IERC721 {
  function safeTransferFrom(address from, address to, uint tokenId) external;

  function transferFrom(address from, address to, uint tokenId) external;
}

contract EnglishAuction {
  event Start();
  event Bid(address indexed sender, uint amount);
  event Withdraw(address indexed bidder, uint amount);
  event End(address winner, uint amount);

  IERC721 nft;
  uint nftId;
  
  address payable public seller;
  uint public endAt;
  bool public started;
  bool public ended;

  address public highestBidder;
  uint public highestBid;
  mapping(address => uint) bidLists;

  constructor(address _nft, uint _nftId, uint _startBid) {
    nft = IERC721(_nft);
    nftId = _nftId;

    seller = payable(msg.sender);
    highestBid = _startBid;
  }

  function start() external {
    require(!started, "already started");
    require(msg.sender == seller, "not started");
  
    nft.transferFrom(seller, address(this), nftId);
    started = true;
    endAt = block.timestamp + 7 days;

    emit Start();
  }

  function bid() external payable {
    require(started, "Not started");
    require(block.timestamp < endAt, "Ended");
    require(msg.value > highestBid, "Not Highest");

    if(highestBidder != address(0)) {
      bidLists[highestBidder] += highestBid;
    }

    highestBidder = msg.sender;
    highestBid = msg.value;

    emit Bid(msg.sender, msg.value);
  }

  function withdraw() external {
    uint value = bidLists[msg.sender];
    bidLists[msg.sender] = 0;
    payable(msg.sender).transfer(value);

    emit Withdraw(msg.sender, value);
  }

  function end() external {
    require(started, "Not started");
    require(block.timestamp >= endAt, "Not ended");
    require(!ended, "ended");

    ended = true;
    if(highestBidder != address(0)) {
      nft.safeTransferFrom(address(this), highestBidder, nftId);
    } else {
      nft.safeTransferFrom(address(this), seller, nftId);
    }

    emit End(highestBidder, highestBid);
  }
}