import "./Ownable.sol";
import "./ProvableAPI.sol";
pragma solidity 0.5.12;

contract Coinflip is Ownable, usingProvable {

  uint public availableMoney;
  uint public lockedMoney;
  uint256 constant NUM_RANDOM_BYTES_REQUESTED = 1;

  event coinFlip(address player, uint result);
  event coinWon(address player, uint value);
  event coinLost(address player, uint value);
  event transferWin(address player, uint value);
  event proofInvalid();

  struct Player {
        uint winnings;
        bool initialized;
    }

    struct Bet {
        address walletAddress;
        uint prediction;
        uint value;
    }

    mapping(address => Player) public players;
    mapping(bytes32 => Bet) public bets;

    modifier checkFlip(uint prediction){
       require(msg.value > 0 && msg.value <= (availableMoney / 2));
       require(prediction == 0 || prediction == 1);
       _;
   }

   constructor()
        public
    {
        provable_setProof(proofType_Ledger);
    }

    function addMoney() public payable returns(uint) {
        require(msg.value > 0);
        availableMoney += msg.value;
        return availableMoney;
    }

    function withdrawMoney() public returns(uint) {
       uint toTransfer = availableMoney;
       availableMoney = 0;
       msg.sender.transfer(toTransfer);
       return toTransfer;
   }

   function transferWins() public returns(uint) {
        require(players[msg.sender].winnings > 0);

        uint toTransfer = players[msg.sender].winnings;
        lockedMoney -= toTransfer;
        players[msg.sender].winnings = 0;
        msg.sender.transfer(toTransfer);
        emit transferWin(msg.sender, toTransfer);
        return toTransfer;
    }

    function placeBet(uint prediction) public payable checkFlip(prediction) {
        uint256 QUERY_EXECUTION_DELAY = 0;
        uint GAS_FOR_CALLBACK = 600000;
        bytes32 queryId = provable_newRandomDSQuery(
            QUERY_EXECUTION_DELAY,
            NUM_RANDOM_BYTES_REQUESTED,
            GAS_FOR_CALLBACK
        );


        Bet memory newBet = Bet(msg.sender, prediction, msg.value);
        bets[queryId] = newBet;
        availableMoney -= msg.value;
        availableMoney -= GAS_FOR_CALLBACK;
        lockedMoney += msg.value * 2;

        if(!players[msg.sender].initialized){
            Player memory newPlayer = Player(0, true);
            players[msg.sender] = newPlayer;
        }
    }

    function __callback(bytes32 _queryId, string memory _result, bytes memory _proof) public {

        require(msg.sender == provable_cbAddress());
        uint _returnCode = provable_randomDS_proofVerify__returnCode(_queryId, _result, _proof);

        if (_returnCode != 0) {
            emit proofInvalid();
        } else {
            uint flip = uint256(keccak256(abi.encodePacked(_result))) % 2;
            emit coinFlip(bets[_queryId].walletAddress, flip);

            //To settle the bet by  adjusting the player's winnings or contract balances
            if(bets[_queryId].prediction == flip) {
                emit coinWon(bets[_queryId].walletAddress, bets[_queryId].value * 2);
                players[bets[_queryId].walletAddress].winnings += bets[_queryId].value * 2;

            } else {
                emit coinLost(bets[_queryId].walletAddress, bets[_queryId].value);
                availableMoney += bets[_queryId].value * 2;
                lockedMoney -= bets[_queryId].value * 2;
            }

            //delete bet from mapping
            delete(bets[_queryId]);
        }
    }

    

}
