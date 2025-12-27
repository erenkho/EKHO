 pragma solidity ^0.4.24;
 
 contract SurveyInterface {

    function submitProposal(string proposalNames, uint _endAt,/* uint [] paymentamounts, uint [] payschedule,*/ uint Id) external returns(bool success);
    function giveRightToVote(address voter) public returns(bool success);
    function delegateVoteTo(address to, uint projectid, address senderAddr) public returns (bool success);
    //function delegateVoteTo(address memberaddr,uint projectid) public
    function vote(uint[] proposal,address cvoter) public returns (bool success);
    function voteTo(uint pId,bool choice, address cvoter) public returns(bool); 
    //function voteForProjectProposal(uint projectid,bool choice) public 
    //function voteForProjectPayment(uint projectid,bool choice) public 
    function getResults(uint numtaken) public view returns(uint[] memory, uint[] memory);
    function sortByVotes() public returns (bool success); 
    function winningProposal() public view returns (uint winningProposal_);
    function winnerName() public view returns (string winnerName_);
    
    
    //function submitProjectProposal(string ipfshash, uint votedeadline,uint [] paymentamounts, uint [] payschedule) public returns (uint projectid) 

    function getCountId() external view returns (uint);
    function getSurveyIpfshash() external view returns (string); 
    function getSurveydeadline() external view returns (uint);
    function getSurveyNumchoices() external view returns (uint);
    function getSurveyAtmostchoice() external view returns (uint);
    function getSurveyOwner() external view returns (address);
 }

 

contract Survey is SurveyInterface {

    string public _surveyIpfshash;
    uint public _surveyDeadline;
    uint public _surveyNumchoices; 
    uint public _surveyAtmostchoice;

    struct Voter {
        uint weight; // weight is accumulated by delegation
        bool voted;  // if true, that person already voted
        address delegate; // person delegated to
        bool vote;   // index of the voted proposal
    }


    struct Proposal {
        // If you can limit the length to a certain number of bytes, 
        // always use one of bytes1 to bytes32 because they are much cheaper
        uint id;
        string name;   // short name (up to 32 bytes)
        uint voteCount; // number of accumulated votes
        //uint [] paymentAmounts;
        //uint [] paySchedule;
        uint startAt;
        uint endAt;
    }


    address public chairperson;

    //Voter[] public voters;

    mapping(address => Voter[]) public votersAdress;

    mapping(uint => Proposal) public proposals;

    mapping(uint => uint) public convertId; //originial Id-> temporary countId

    uint public countId;//temporary number of submitted proposals

    constructor(string ipfshash,uint deadline,uint numchoices, uint atmostchoice, address owner) public {
        chairperson = owner;
        _surveyIpfshash=ipfshash;
        _surveyDeadline=deadline;
        _surveyNumchoices=numchoices; //max number of proposals can be funded by this survey
        _surveyAtmostchoice=atmostchoice; //max number of winning proposals
        countId=0;
        require(deadline >= block.timestamp, "end at < start at");
        require(deadline <= block.timestamp + 90 days, "end at > max duration");
    
    }

    function submitProposal(string proposalNames, uint _endAt,/* uint [] paymentamounts, uint [] payschedule,*/ uint Id) external returns (bool success) {
        require(_endAt >= block.timestamp, "end at < start at");
        require(_endAt <= block.timestamp + 90 days, "end at > max duration");
        require(countId < _surveyNumchoices, "No more project can be submited for this survey.");
            // 'Proposal({...})' creates a temporary
            // Proposal object and 'proposals.push(...)'
            // appends it to the end of 'proposals'.
            
            convertId[Id]=countId;
            
            proposals[countId]=Proposal({
                id: Id,
                name: proposalNames,
                voteCount: 0,
                //paymentAmounts: paymentamounts,
                //paySchedule: payschedule,
                startAt: block.timestamp,
                endAt: _endAt
            });
            countId +=1;
        return true;
        
    }

    function getCountId() external view returns (uint) {
        return (countId);
    }
    function getSurveyIpfshash() external view returns (string) {
        return (_surveyIpfshash);
    }
    function getSurveydeadline() external view returns (uint) {
        return (_surveyDeadline);
    }
    function getSurveyNumchoices() external view returns (uint) {
        return (_surveyNumchoices);
    }
    function getSurveyAtmostchoice() external view returns (uint) {
        return (_surveyAtmostchoice);
    }
    function getSurveyOwner() external view returns (address) {
        return (chairperson);
    }
    /** 
     * @dev Give 'voter' the right to vote on this ballot. May only be called by 'chairperson'.
     * @param voter address of voter
     */
    function giveRightToVote(address voter) public returns (bool success) {

        //require(votersAdress[voter][countId].weight == 0);
        //votersAdress[voter][countId].weight = 1;

        for(uint i=0; i<_surveyNumchoices; i++){
                votersAdress[voter].push(Voter({
            weight:1,
            voted:false,
            delegate:0,
            vote:false}));
            }
        return true;

    }

    /**
     * @dev Delegate your vote to the voter 'to'.
     * @param to address to which vote is delegated
     */
    function delegateVoteTo(address to, uint projectId, address senderAddr) public returns (bool success){//CODE FOR EACH PROPOSAL
        uint projectid=convertId[projectId];

        Voter storage sender = votersAdress[senderAddr][projectid];
        require(!sender.voted, "You already voted.");
        require(to != senderAddr, "Self-delegation is disallowed.");

        //Allows us to find the last person who all the votes are delegated to
        while (votersAdress[to][projectid].delegate != address(0)) {
            to = votersAdress[to][projectid].delegate;

            // We found a loop in the delegation, not allowed.
            require(to != senderAddr, "Found loop in delegation.");
        }
        sender.voted = true;
        sender.delegate = to;
        Voter storage delegate_ = votersAdress[to][projectid];
        if (delegate_.voted) {
            // If the delegate already voted "yes,
            // directly add to the number of votes
            if(delegate_.vote){
            proposals[projectid].voteCount += sender.weight;}
        } else {
            // If the delegate did not vote yet,
            // add to her weight.
            delegate_.weight += sender.weight;
        }

        return true;
    }

    /**
     * @dev Give your vote (including votes delegated to you) to proposal 'proposals[proposal].name'.
     * @param proposal index of proposal in the proposals array
     */
    function vote(uint[] proposal,address cvoter) public returns(bool){
        for (uint p=0; p< _surveyNumchoices; p++){
        if(proposal[p]!=1&&proposal[p]!=0){continue;}

        
        //Voter storage sender = votersAdress[cvoter][p];
        if(proposal[p]==1){
            voteTo(p,true,cvoter);}
            else
                {voteTo(p,false,cvoter);
            }    
        /*require(sender.weight != 0, "Has no right to vote");
        require(!sender.voted, "Already voted.");
        sender.voted = true;
        sender.vote = true;
        // If 'proposal' is out of the range of the array,
        // this will throw automatically and revert all
        // changes.
        proposals[p].voteCount += sender.weight;}
            else{
            require(sender.weight != 0, "Has no right to vote");
            require(!sender.voted, "Already voted.");
            sender.voted = true;
            sender.vote = false;
            }*/
        }
        return true;
    }

    function voteTo(uint prjId,bool choice, address cvoter) public returns(bool){        
        uint pId=convertId[prjId];

        Voter storage sender = votersAdress[cvoter][pId];
        if(choice==true){    
        require(sender.weight != 0, "Has no right to vote");
        require(!sender.voted, "Already voted.");
        sender.voted = true;
        sender.vote = true;
        // If 'proposal' is out of the range of the array,
        // this will throw automatically and revert all
        // changes.
        proposals[pId].voteCount += sender.weight;}
            else{
            require(sender.weight != 0, "Has no right to vote");
            require(!sender.voted, "Already voted.");
            sender.voted = true;
            sender.vote = false;
            }
        
        return true;}

    /** 
     * @dev Computes the winning proposal taking all previous votes into account.
     * @return winningProposal_ index of winning proposal in the proposals array
     */
    function winningProposal() public view
            returns (uint winningProposal_)
    {   

        uint winningVoteCount = 0;
        for (uint p = 0; p < _surveyNumchoices; p++) {
            if (proposals[p].voteCount > winningVoteCount) {
                winningVoteCount = proposals[p].voteCount;
                winningProposal_ = p;
            }
        }
    }
    //uint[] public voteCounts;        
    //function getVoteCount(uint p) public {
      //      for(uint i=0; i<_surveyNumchoices;i++){
        //    Proposal storage prop = proposals[i];
          //  voteCount[i]=prop.voteCount;
           // }       
    //}

    function sortByVotes() public returns (bool success){
        

        for (uint i = 1; i < _surveyNumchoices; i++){
            for (uint j = 0; j < i; j++)
                if (proposals[j].voteCount < proposals[i].voteCount) {
                    Proposal memory x = proposals[j];
                    proposals[j] = proposals[i];
                    proposals[i] = x;
                }}
        return true;
}
    function getResults(uint numtaken) public view returns(uint[] memory, uint[] memory) {
        
        uint[] memory voteCounts = new uint[](numtaken);
        uint[] memory projectId = new uint[](numtaken);
        for(uint i=0; i<numtaken; i++){
        Proposal storage prop = proposals[i];
        voteCounts[i]=prop.voteCount;
        projectId[i]=prop.id;
        }
        return(projectId,voteCounts);
    }


    /** 
     * @dev Calls winningProposal() function to get the index of the winner contained in the proposals array and then
     * @return winnerName_ the name of the winner
     */
    function winnerName() public view
            returns (string winnerName_)
    {
        winnerName_ = proposals[winningProposal()].name;
    }
}
