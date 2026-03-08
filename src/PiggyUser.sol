// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import "./PiggyBank.sol";

contract PiggyUser {
    struct PiggyDetails {
        string yourPurpose;
        uint256 deadline;
        address owner;
        address piggyContractAddress;
    }

    address developerAddress;
    mapping(address => PiggyDetails[]) public userPiggyBanks;
    address[] public piggyBankfactoryAddress;
    mapping(address => uint256) public userCounter;

    event PiggyBankCreated(address indexed owner, address indexed piggyContract, string purpose);


    constructor() {
        developerAddress = msg.sender;
    }

    function savingPurpose(string memory _purpose, uint256 _deadline) public {
        uint256 counter = userCounter[msg.sender];
        bytes32 salt = keccak256(abi.encodePacked(msg.sender, counter));
        PiggyBank piggyContract = new PiggyBank{salt: salt}(msg.sender, _purpose, _deadline, developerAddress);

        userPiggyBanks[msg.sender].push(
            PiggyDetails({
                yourPurpose: _purpose,
                deadline: _deadline,
                owner: msg.sender,
                piggyContractAddress: address(piggyContract)
            })
        );
        piggyBankfactoryAddress.push(address(piggyContract));
        userCounter[msg.sender]++;

        emit PiggyBankCreated(msg.sender, address(piggyContract), _purpose);
    }

    function getUserPiggyBanks(address _user) public view returns (PiggyDetails[] memory) {
        return userPiggyBanks[_user];
    }

    function getAllPiggyBanks() public view returns (address[] memory) {
        return piggyBankfactoryAddress;
    }

    function predictContractAddress( string memory _purpose,
    uint256 _deadline) external view returns (address) {
        uint256 counter = userCounter[msg.sender];
        bytes32 salt = keccak256(abi.encodePacked(msg.sender, counter));
        bytes memory bytecode = abi.encodePacked(type(PiggyBank).creationCode, abi.encode(msg.sender, _purpose, _deadline, developerAddress));

        return
            address(
                uint160(uint256(keccak256(abi.encodePacked(bytes1(0xff), address(this), salt, keccak256(bytecode)))))
            );
    }
}
