pragma solidity ^0.4.2;

contract ProxyTarget {  
    constructor() public {}  
}

// From https://github.com/ethereumjs/testrpc/issues/58
contract EstimateGas {
    event Add(bytes32 name, bytes32 description, uint value, address owner);

    struct Test {
        bytes32 name;
        bytes32 description;
        uint[] balances;
        mapping(address => uint) owners;
    }

    uint256 public x;
    function reset() public {
        x = 0;
    }
    function triggerRsclearRefund() public {
        x = gasleft();
        reset();
    }
    function triggerRselfdestructRefund() public {
        selfdestruct(msg.sender);
    }
    function triggerAllRefunds() public {
        triggerRsclearRefund();
        triggerRselfdestructRefund();
    }
    function gasStipend() public {
        this.reset.gas(10000)();
    }

    mapping(bytes32 => uint) index;
    Test[] tests;

    function EstimateGas() {
        tests.length++;
    }
    
    function deposit() public payable {}
    function withdraw() public {
        msg.sender.transfer(address(this).balance);
    }

    function callOtherContract() public {  
        new ProxyTarget();
    } 

    function add(bytes32 _name, bytes32 _description, uint _value) returns(bool) {
        if (index[_name] != 0) {
            return false;
        }
        uint pos = tests.length++;
        tests[pos].name = _name;
        tests[pos].description = _description;
        tests[pos].balances.length = 2;
        tests[pos].balances[1] = _value;
        tests[pos].owners[msg.sender] = 1;
        index[_name] = pos;
        Add(_name, _description, _value, msg.sender);
        return true;
    }

    function transfer(address _to, uint _value, bytes32 _name) returns(bool) {
        uint pos = index[_name];
        if (pos == 0) {
            return false;
        }

        uint posFrom = tests[pos].owners[msg.sender];
        if (posFrom == 0) {
            return false;
        }

        if (tests[pos].balances[posFrom] < _value) {
            return false;
        }

        uint posTo = tests[pos].owners[_to];
        if (posTo == 0) {
            uint posBal = tests[pos].balances.length++;
            tests[pos].owners[_to] = posBal;
            posTo = posBal;
        }

        if (tests[pos].balances[posTo] + _value < tests[pos].balances[posTo]) {
            return false;
        }
        tests[pos].balances[posFrom] -= _value;
        tests[pos].balances[posTo] += _value;

        return true;
    }
}
