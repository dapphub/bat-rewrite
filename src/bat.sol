pragma solidity ^0.4.8;
import 'ds-token/token.sol';

contract BATCrowdsale {
    DSToken BAT;

    address custodian;
    uint custodianBonus;
    uint saleStart;
    uint saleEnd;
    uint limit;
    uint minimum;
    bool done; // set true on finalize
    bool ok;   // set true on finalize only if all conditions met

    function BATCrowdsale(address custodian_, uint saleStart_, uint saleEnd_)
    {
        BAT = new DSToken();
        BAT.stop(); // Don't allow ERC20 actions during the sale.
        custodian = custodian_;
        saleStart = saleStart_;
        saleEnd = saleEnd_;
    }
    function buy()
        payable
    {
        assert( saleStart <= now && now <= saleEnd );
        assert( BAT.totalSupply() + msg.value <= limit );
        BAT.mint(msg.sender, msg.value);
    }
    function finalize()
        auth
    {
        assert( saleEnd < now );
        var supply = BAT.totalSupply();
        done = true;
        // limit check is implicit via `buy`
        ok = (minimum <= supply) && (supply <= limit);
        if( ok ) {
            // TODO compute ratio
            BAT.mint(custodian, custodianBonus);
            BAT.flow(); // re-enable ERC20 actions
            BAT.setOwner(msg.sender);
        }
    }
    function refund()
    {
        assert( done && !ok );
        var bal = BAT.balanceOf(msg.sender);
        BAT.burn(msg.sender, bal);
        msg.sender.call.value(bal)();
    }
}
