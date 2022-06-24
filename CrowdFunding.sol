//SPDX-License-Identifier: GPL-3.0

/*

This is a crowdfunding contract
To deploy the contract there are 2 variables needed which are: goal ammount and deadline
The minimum contribution ammount to the contract is 100 wei
Admin of the contract can request transfers to other accounts which may be fundraisings
Each contributor can vote on the admins requests
At least 50% of the votes are required for a request to be approved
Contributors have full control over spending requests

*/

pragma solidity 0.8.7;

contract crowdFunding{
    mapping (address => uint) public contributors;
    address public admin;
    uint public number_of_contributors;
    uint public minimum_contribution;
    uint public deadline; //timestamp
    uint public goal;
    uint public raised_ammount;

    struct Request{
        string description;
        address payable recipient;
        uint value;
        bool completed;
        uint noOfVoters;
        mapping(address => bool) voters;
    }

    mapping(uint => Request) public requests;
    uint numRequests;

    constructor(uint _goal, uint _deadline){
        goal = _goal;
        deadline = _deadline + block.timestamp;
        minimum_contribution = 100 wei;
        admin = msg.sender;
    }

    event ContributeEvent(address _sender, uint _value);
    event CreateRequestEvent(string _description, address _recipient, uint _value);
    event MakePaymentEvent(address _recipient, uint _value);

    function contribute() public payable{
        require(block.timestamp < deadline, "Deadline has passed!");
        require(msg.value >= minimum_contribution, "Minimum contribution not met!"); //100 wei

        if(contributors[msg.sender]==0){
            number_of_contributors++;
        }

        contributors[msg.sender] += msg.value;
        raised_ammount += msg.value;

        emit ContributeEvent(msg.sender, msg.value);
    }

    receive() payable external{
        contribute();
    }

    function getBalance() public view returns(uint){
        return address(this).balance;
    }

    function getRefund() public{
        require(block.timestamp > deadline && raised_ammount < goal);//if the deadline has passed and raised ammount does not meet the goal
        require(contributors[msg.sender]>0); //the one that calls this function must be a contributor and still have ethereum in the contract balance

        address payable recipient = payable(msg.sender);
        uint value = contributors[msg.sender];
        recipient.transfer(value);

        contributors[msg.sender] = 0;

    }

    modifier onlyAdmin(){
        require(msg.sender == admin, "Only the admin can call this function!");
        _;
    }

    function createRequest(string memory _description, address payable _recipient, uint _value) public onlyAdmin{
        Request storage newRequest = requests[numRequests];
        numRequests++;

        newRequest.description = _description;
        newRequest.recipient = _recipient;
        newRequest.value = _value;
        newRequest.completed = false;
        newRequest.noOfVoters = 0;

        emit CreateRequestEvent(_description,_recipient,_value);

    }

    function voteRequest(uint _requestNo) public{
        require(contributors[msg.sender]>0,"you must be a contributor to vote!");
        Request storage thisRequest = requests[_requestNo];

        require(thisRequest.voters[msg.sender] == false, "you have voted already!");
        thisRequest.voters[msg.sender] = true;
        thisRequest.noOfVoters++;

    } 

    function makePayment(uint _requestNo) public onlyAdmin{
        require(raised_ammount >= goal);
        Request storage thisRequest = requests[_requestNo];
        require(thisRequest.completed == false, "The request has been completed");
        require(thisRequest.noOfVoters > (number_of_contributors / 2)); //50%  voted for the request

        thisRequest.recipient.transfer(thisRequest.value);
        thisRequest.completed = true;

        emit MakePaymentEvent(thisRequest.recipient,thisRequest.value);

    }

}
