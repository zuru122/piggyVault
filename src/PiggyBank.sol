// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import "./interface/IERC20.sol";

// import "../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract PiggyBank {
    //duration ✅
    //penalty ✅
    //deposit ✅
    //withraw ✅
    //developerAddress
    // isWithdrawn
    // onlyOwnerModifer
    //supported tokens

    // uint public startTime;
    // uint public endTime;

    address public developerAddress;
    address public owner;
    string public purpose;
    uint256 public startTime;
    uint256 public deadline;
    address[3] public supportedToken;
    uint256 public penaltyPercentage;

    error Unauthorized();
    error InvalidAddress();
    error NotSupported(address);
    error InsufficientFunds();

    modifier onlyOwner() {
        if (msg.sender != owner) revert Unauthorized();
        _;
    }

    mapping(address => mapping(address => uint256)) public balances; // user => token => balance
    mapping(address => bool) public withdrawnByToken;

    constructor(address _owner, string memory _purpose, uint256 _deadline, address _developersAddress) {
        owner = _owner;
        purpose = _purpose;
        startTime = block.timestamp;
        deadline = _deadline;
        penaltyPercentage = 15;

        // Real Token

        address USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
        address USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
        address DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;

        supportedToken = [USDT, USDC, DAI];
        developerAddress = _developersAddress;

        // Setting of supported token (tokenSupported)
        for (uint256 i; i < supportedToken.length; i++) {
            address token = supportedToken[i];
            tokenSupported[token] = true;
        }
    }

    mapping(address => bool) tokenSupported;

    // Deposit

    function deposit(uint256 _amount, address _tokenAddress) public returns (bool success) {
        if (_tokenAddress == address(0)) revert InvalidAddress();
        if (!tokenSupported[_tokenAddress]) revert NotSupported(_tokenAddress);

        require(IERC20(_tokenAddress).allowance(msg.sender, address(this)) >= _amount, "Not enough allowance");

        IERC20(_tokenAddress).transferFrom(msg.sender, address(this), _amount);

        balances[msg.sender][_tokenAddress] += _amount;

        return true;
    }

    function withdraw(address _token) public onlyOwner returns (bool success) {
        require(!withdrawnByToken[_token], "Already withdrawn");
        uint256 balance = balances[msg.sender][_token];

        if (balance == 0) revert InsufficientFunds();

        if (block.timestamp >= deadline) {
            IERC20(_token).transfer(owner, balance);
        } else {
            uint256 penaltyAmount = (balance * penaltyPercentage) / 100;
            uint256 amountToWithdraw = balance - penaltyAmount;

            IERC20(_token).transfer(owner, amountToWithdraw);
            IERC20(_token).transfer(developerAddress, penaltyAmount);
        }

        withdrawnByToken[_token] = true;
        balances[msg.sender][_token] = 0;
        return true;
    }

    function getEmergencyBalance(address _token) public view returns (uint256) {
        return IERC20(_token).balanceOf(address(this));
    }

    // function emergencyWithdraw(address _token) public onlyOwner {
    //     uint256 contractBalance = IERC20(_token).balanceOf(address(this));
    //     if (contractBalance == 0) revert InsufficientFunds();

    //     IERC20(_token).transfer(owner, contractBalance);
    // }
}
