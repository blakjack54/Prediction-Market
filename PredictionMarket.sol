// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract PredictionMarket {
    struct Market {
        string description;
        uint256 endTime;
        uint256 totalYes;
        uint256 totalNo;
        bool resolved;
        bool outcome;
        mapping(address => uint256) yesBets;
        mapping(address => uint256) noBets;
    }

    uint256 public marketCount;
    mapping(uint256 => Market) public markets;

    event MarketCreated(uint256 marketId, string description, uint256 endTime);
    event BetPlaced(uint256 marketId, address better, bool betYes, uint256 amount);
    event MarketResolved(uint256 marketId, bool outcome);
    event WinningsClaimed(uint256 marketId, address claimant, uint256 amount);

    function createMarket(string memory description, uint256 duration) external {
        marketCount++;
        markets[marketCount] = Market(description, block.timestamp + duration, 0, 0, false, false);
        emit MarketCreated(marketCount, description, block.timestamp + duration);
    }

    function placeBet(uint256 marketId, bool betYes) external payable {
        Market storage market = markets[marketId];
        require(block.timestamp < market.endTime, "Betting period over");
        require(!market.resolved, "Market already resolved");

        if (betYes) {
            market.totalYes += msg.value;
            market.yesBets[msg.sender] += msg.value;
        } else {
            market.totalNo += msg.value;
            market.noBets[msg.sender] += msg.value;
        }

        emit BetPlaced(marketId, msg.sender, betYes, msg.value);
    }

    function resolveMarket(uint256 marketId, bool outcome) external {
        Market storage market = markets[marketId];
        require(block.timestamp >= market.endTime, "Market not ended yet");
        require(!market.resolved, "Market already resolved");

        market.resolved = true;
        market.outcome = outcome;
        emit MarketResolved(marketId, outcome);
    }

    function claimWinnings(uint256 marketId) external {
        Market storage market = markets[marketId];
        require(market.resolved, "Market not resolved yet");

        uint256 winnings;
        if (market.outcome) {
            winnings = market.yesBets[msg.sender] + ((market.totalNo * market.yesBets[msg.sender]) / market.totalYes);
            market.yesBets[msg.sender] = 0;
        } else {
            winnings = market.noBets[msg.sender] + ((market.totalYes * market.noBets[msg.sender]) / market.totalNo);
            market.noBets[msg.sender] = 0;
        }

        require(winnings > 0, "No winnings to claim");
        payable(msg.sender).transfer(winnings);
        emit WinningsClaimed(marketId, msg.sender, winnings);
    }
}
