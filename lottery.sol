//SPDX-License-Identifier: GPL-3.0

//This is a lottery smart contract
//Whoever want to participate in the lottery must send 0.1 ether to the address of the contract
//0.1 ether = 100000000 GWei
//0.1 ether = 100000000000000000 Wei
//Only the smart contract owner, who deploys the contract, can decide to pick the winner
//2% of the contract balance goes to the owner of the contract as a commission or cut
//Rest of the balance (98%) goes to the winner
//There must be at least 3 participants for the smart contract to work

pragma solidity 0.8.7;

contract lottery{

    address payable[] public players; //participants
    address payable public manager; //owner of the smart contract

    constructor(){
        manager = payable(msg.sender);
    }

    receive() external payable{
        require(msg.value == 0.1 ether); //participants must send 0.1 ether
        players.push(payable(msg.sender));
    }

    function getBalance() public view returns(uint){
        require(msg.sender == manager);
        return address(this).balance;
    }

    function randomNumberGenerator() public view returns(uint){
        //random number generator to pick the winner
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, players.length)));
    }


    // select the winner for the lottery
    function getWinner() public view returns(address payable){
        require(msg.sender == manager);
        require(players.length >= 3); //there must be at least 3 participants

        uint random_number = randomNumberGenerator();
        address payable winner;

        uint index = random_number % players.length;

        winner = players[index];
        return winner;
    }

    //paying the winner and the owner of the contract
    function payWinner() public{
        require(msg.sender == manager);
        
        address payable winner = getWinner();

        //conract creator gets 2% cut from the lottery
        manager.transfer(getBalance()/50);
        //rest of the balance which is 98% goes to the lottery winner
        winner.transfer(getBalance());
        //resetting the lottery
        players = new address payable[](0);
    }

}
