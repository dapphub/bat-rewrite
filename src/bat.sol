// (C) 2016 DappHub, LLC

pragma solidity ^0.4.8;

import 'ds-token/token.sol';
import 'ds-math/math.sol';
import 'ds-exec/exec.sol';

contract BATCrowdsale is DSAuth // access control
                       , DSMath // safe math
                       , DSExec // safe calls
{
    DSToken BAT;

    address custodian;
    uint custodianRatio; // as a whole number of percent, e.g. 30 -> 30%
    uint limit;
    uint minimum;
    uint saleStart;
    uint saleEnd;
    bool done; // set true on finalize
    bool ok;   // set true on finalize only if all conditions met

    function BATCrowdsale(address custodian_, uint saleStart_, uint saleEnd_)
    {
        BAT = new DSToken("BAT", "Brave Access Token", 18);
        BAT.stop(); // Don't allow ERC20 actions until/unless sale succeeds
        custodian = custodian_;
        saleStart = saleStart_;
        saleEnd = saleEnd_;
    }
    function buy()
        payable
    {
        assert( saleStart <= now && now <= saleEnd );
        assert( BAT.totalSupply() + msg.value <= limit );
        // TODO if you want something other than 1:1, do conversion here
        var payout = cast(msg.value);
        BAT.mint(payout);
        BAT.push(msg.sender, payout);
    }
    function finalize()
        auth
    {
        assert( saleEnd < now );
        var supply = BAT.totalSupply();
        done = true;
        ok = (minimum <= supply) && (supply <= limit);
        if( ok ) { // create dev allocation and pop off token
            // TODO update with formula specified in original
            var reward = cast(supply * custodianRatio / 100);
            BAT.mint(reward);
            BAT.push(custodian, reward);
            BAT.start(); // re-enable ERC20 actions
            BAT.setOwner(msg.sender);
            exec(msg.sender, this.balance);
        }
    }
    function refund()
    {
        assert( done && !ok );
        var bal = cast(BAT.balanceOf(msg.sender));
        BAT.pull(msg.sender, bal);
        BAT.burn(bal);
        exec(msg.sender, uint(bal));
    }
}

// For easier instantiation from multisig
contract BATCrowdsaleFactory {
    function make(address c, uint s, uint e) returns (BATCrowdsale) {
        return new BATCrowdsale(c, s, e);
    }
}

