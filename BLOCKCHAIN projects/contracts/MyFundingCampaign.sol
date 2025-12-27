pragma solidity ^0.4.24;


contract FundingCampaign{
    
    struct Withdrawal{
        string description;
        uint [] paymentamounts;
        uint [] payschedule;
        address recipient;
        bool complete;
        uint approvalCount;
        mapping(address => bool) approvals;
    }

    //Withdrawal[] public withdrawals;
    mapping(uint=>Withdrawal) withdrawals;
    address public owner;
    //mapping(address=>bool) contributors;
    //uint public contributorsCount;

    constructor( address creator) public{
        owner=creator;
    }

    /*function contribute() public payable{
        contributors[msg.sender]=true;
        contributorsCount++;
    }*/

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    struct Subscription {
    bool valid;
    uint start;
    uint nextPayment;
    uint currentState;
  }
    mapping(uint => Subscription) public subscriptions;

  event SubscriptionCreated(
    address subscriber,
    uint planId,
    uint date
  );
  event SubscriptionCancelled(
    address subscriber,
    uint planId,
    uint date
  );

  event PaymentSent(
    address from,
    address to,
    uint amount,
    uint planId,
    uint date
  );

  function subscribe(uint Id) public {
    Withdrawal storage withdrawal = withdrawals[Id];
    require(withdrawal.recipient != address(0), 'this plan does not exist');

    //withdrawal.recipient.transfer(withdrawal.paymentamounts[0]);

    subscriptions[Id] = Subscription(
        true,
        block.timestamp,
        block.timestamp + withdrawal.payschedule[0],
        0);

    emit SubscriptionCreated(msg.sender, Id, block.timestamp);
  }

  function cancel(uint Id) public {
    Subscription storage subscription = subscriptions[Id];
    require(
      subscription.valid != false, 
      'this subscription does not exist'
    );
    delete subscriptions[Id]; 
    emit SubscriptionCancelled(msg.sender, Id, block.timestamp);
  }

    /*function isPaymentAllowed(uint Id) public returns(bool success){
    Subscription storage subscription = subscriptions[Id];
    Withdrawal storage withdrawal = withdrawals[Id];
    require(
      subscription.valid != false, 
      'this subscription does not exist'
    );
    require(
      block.timestamp > subscription.nextPayment,
      'not due yet'
    );

    //token.transferFrom(subscriber, plan.merchant, plan.amount);  

    subscription.nextPayment = subscription.nextPayment + withdrawal.paymentamounts[subscription.currentState];
    subscription.currentState++;
    return true;
  }*/

    /*modifier onlyContributer() {
        require(contributors[msg.sender]);
        _;    
    }*/

    function createWithdrawal(uint id, string description,uint [] paymentamounts, uint [] payschedule, address recipient) public{
        Withdrawal memory newWithdrawal = Withdrawal({
            description: description,
            paymentamounts: paymentamounts,
            payschedule: payschedule,
            recipient: recipient,
            complete: false,
            approvalCount: 0
        });

        withdrawals[id]=(newWithdrawal);
        subscribe(id);
    }

    function approvalWithdrawal(uint index, bool choice) public {
        require(choice);
        Withdrawal storage withdrawal = withdrawals[index];

        require(!withdrawal.approvals[msg.sender], "Already voted for payment!");

        withdrawal.approvals[msg.sender]=true;
        withdrawal.approvalCount++;

    }

    function finalizeWithdrawal(uint index, uint membersCount) public {
      Withdrawal storage withdrawal =withdrawals[index];

      require(withdrawal.approvalCount >= (membersCount/100));
      require(!withdrawal.complete);
        
      Subscription storage subscription = subscriptions[index];
      require(subscription.valid != false, 'this subscription does not exist');
      require(block.timestamp > subscription.nextPayment,'not due yet');

     //token.transferFrom(subscriber, plan.merchant, plan.amount);  
      withdrawal.recipient.transfer(withdrawal.paymentamounts[subscription.currentState]);
      //withdrawal.complete = true;

      subscription.nextPayment = subscription.nextPayment + withdrawal.paymentamounts[subscription.currentState];
      subscription.currentState++;

      
    }

      function() external payable{      
  }

}