//SPDX-License-Identifier: GPL-3.0

/*
This is a token smart contract and an ico smart contract that is written with ERC-20 standards.
@berkayaydins
*/


pragma solidity >=0.5.0 <0.9.0;

interface ERC20token{
    function totalSupply() external view returns(uint);
    function balanceOf(address tokenOwner) external view returns(uint balance);
    function transfer(address to, uint tokens) external returns(bool success);

    function allowance(address tokenOwner, address spender) external view returns(uint remaining);
    function approve(address spender, uint tokens) external returns(bool success);
    function transferFrom(address from, address to, uint tokens) external returns(bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);

}

contract Aydins is ERC20token{
    string public name = "Aydins";
    string public symbol = "AYDN";
    uint public decimals = 0;
    uint public override totalSupply;

    address public founder;
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) allowed;

    constructor(){
        totalSupply = 1000000;
        founder = msg.sender;
        balances[founder] = totalSupply;
    }

    function balanceOf(address tokenOwner) public view override returns(uint balance){
        return balances[tokenOwner];
    }

    function transfer(address to, uint tokens) public virtual override returns(bool success){
        require(balances[msg.sender] >= tokens);
        balances[to] += tokens;
        balances[msg.sender] -= tokens;
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    function allowance(address tokenOwner, address spender) view public override returns(uint){
        return allowed[tokenOwner][spender];
    }

    function approve(address spender, uint tokens) public override returns(bool success){
        require(balances[msg.sender]>=tokens);
        require(tokens>0);

        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    function transferFrom(address from, address to, uint tokens) public virtual override returns(bool success){
        require(allowed[from][msg.sender]>=tokens);
        require(balances[from]>=tokens);

        balances[from] -= tokens;
        allowed[from][msg.sender] -= tokens;

        balances[to] += tokens;
        emit Transfer(from, to, tokens);
        return true;
    }

}

contract AydinsICO is Aydins{
    address public admin;
    address payable public deposit;
    uint tokenPrice = 0.0001 ether; // 1 ETH = 1000 AYDN
    uint public hardcap = 300 ether;
    uint public raisedAmmount;
    uint public saleStart = block.timestamp;
    uint public saleEnd = block.timestamp + 60480; // ends in one week
    uint public tokenTradeStart = saleEnd + 60480; // one week after the sale ends
    uint public maxInvestment = 5 ether;
    uint public minInvestment = 0.1 ether;

    enum State{beforeStart, running, afterEnd, halted}
    State public icoState;

    constructor(address payable _deposit){
        deposit = _deposit;
        admin = msg.sender;
        icoState = State.beforeStart;

    }

    modifier onlyAdmin(){
        require(msg.sender == admin);
        _;
    }

    function halt() public onlyAdmin{
        icoState = State.halted;
    }

    function resume() public onlyAdmin{
        icoState = State.running;
    }

    function changeDepositAddress(address payable _deposit) public onlyAdmin{
        deposit = _deposit;
    }

    function getCurrentState()public view returns(State){
        if(icoState == State.halted){
            return State.halted;
        }else if(block.timestamp < saleStart){
            return State.beforeStart;
        }else if(block.timestamp>=saleStart && block.timestamp<=saleEnd){
            return State.running;
        }else{
            return State.afterEnd;
        }
    }

    event Invest(address investor, uint value, uint tokens);

    function invest() payable public returns(bool){
        icoState = getCurrentState();
        require(icoState == State.running);
        require(msg.value >= minInvestment && msg.value <= maxInvestment);
        require((raisedAmmount+msg.value)<=hardcap);

        raisedAmmount += msg.value;
        uint tokens = msg.value / tokenPrice;
        balances[msg.sender] += tokens;
        balances[founder] -= tokens;
        deposit.transfer(msg.value);

        emit Invest(msg.sender, msg.value, tokens);

        return true;
    }

    receive() payable external{
        invest();
    }

    function transfer(address to, uint tokens) public override returns(bool success){
        require(block.timestamp>tokenTradeStart);
        Aydins.transfer(to, tokens);
        return true;
    }

    function transferFrom(address from, address to, uint tokens) public override returns(bool success){
        require(block.timestamp>tokenTradeStart);
        Aydins.transferFrom(from, to, tokens);
        return true;
    }

    function burn() public returns(bool){
        icoState = getCurrentState();
        require(icoState == State.afterEnd);
        balances[founder] = 0;
        return true;
    }

}
