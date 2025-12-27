pragma solidity ^0.4.24;

import "./MyGovToken.sol";
import "./MySurvey.sol";
import "./MyFundingCampaign.sol";


contract MyMainContract{

    struct Project{
        /*string description;
        uint value;
        address recipient;
        bool complete;
        uint approvalCount;
        mapping(address => bool) approvals;*/

        string ipfsHash;
        uint voteDeadline;//deadline for the survey
        uint[] paymentAmounts;//how much ether is needed 
        uint[] paySchedule;//payments are scheduled
        address recipient;//project proposer
        uint voteCount;
        uint approvalCount; //payment approvals count
        bool approved;
        bool funded;
    }

    //Project[] public projects;
    mapping(uint=>Project) projects; //(ProjectId uint) -> (Project struct)
    uint public Id;

    address[] members;
    mapping(address=>bool) public isMember;
    mapping(address=>bool) contributors;//donators
    uint public contributorsCount;
    uint public membersCount;
    uint public fundedProjectCount;
    uint public surveysCount;

    //votes, proposals
    //event members
    event SurveyAdresses(address _SurveyAdresses);

    //Calling the Another Contract
    GovToken public MyGov;
    //Calling the Another Contract
    Survey public MySurvey;
    //Calling the Another Contract
    FundingCampaign public MyFundingCampaign;

    address[] public fundedProjects;

    //creates a campaign for funded projects
    function createCampaign() public{
        MyFundingCampaign = new FundingCampaign(msg.sender);
        //fundedProjects.push(MyFundingCampaign);
    }

    //function getDeployedCampaigns() public view returns (address[]){
      //  return fundedProjects;
    //}
    
    //9. MyGov token supply is 10 million (fixed).
    constructor(uint tokenSupply) public{
    MyGov= new GovToken(tokenSupply);
    createCampaign();
    }

    //Calling the Function of Another Contract
    function getTokenSupply() public view returns (uint result) {
        return MyGov.totalSupply();
    }
        //allow users to call the requestTokens function to mint tokens
    
    //11.MyGov tokens are distributed via a faucet function. Faucet gives 1 token to an address.
    //If the address obtained a token before, it cannot get token from faucet any longer
    //Anyone can get a token once.
    function faucet() public payable returns(bool success){
        MyGov.giveToken(msg.sender);
        //3. Anyone who owns at least 1 MyGov token is MyGov member.
        isMember[msg.sender]=true;
        members.push(msg.sender);
        membersCount++;
        if(isSurveyDeployed){
            MySurvey.giveRightToVote(msg.sender);//gives right to vote for existing survey
        }
        return true;
    }

    function BuyToken(uint amnt) public payable returns(bool success){
        MyGov.buy(amnt, msg.value, msg.sender);
        return true;
    }
    function SellToken(uint amnt) public payable returns(bool success){
        //payable(_sender).transfer(amount);
        address(uint160(msg.sender)).transfer( MyGov.sell(amnt, msg.sender));
        
        return true;
    }

    function getBalanceOf(address tokenOwner) public view returns (uint balance){
        return MyGov.balanceOf(tokenOwner);
    }

    //Modifier for only the members, rest of the code is executed when the msg sender is a member
    modifier onlyMembers() {
        require(isMember[msg.sender], "Only members!");
        _;    
    }

    //12.Members can delegate vote.
    // Members who voted or delegated vote cannot reduce their MyGov balance to zero until the voting deadlines.
    function delegateVoteTo(address memberaddr,uint projectid) public onlyMembers{
    MySurvey.delegateVoteTo(memberaddr,projectid,msg.sender);
    }

    function contribute() public payable{
        contributors[msg.sender]=true;
        contributorsCount++;
    }

    //takes value from msg.value
    function donateEther() public payable{
        MyGov.donateEther(msg.value);
        contribute();
    } 

    //Transfers ether to other contract
      function fundtransfer() public payable {
      address(MyFundingCampaign).transfer(address(this).balance);
    }
  
    function() external payable{}

    //10. Donations can be accepted in ethers and MyGov tokens only. Ethers can be granted to winning Project proposals.
    function donateMyGovToken(uint amount) public payable{
        MyGov.donateMyGovToken(amount); 
    } 

    //imputs are which project you are voting and what answer you give (yes/no)
    function voteForProjectProposal(uint projectid,bool choice) public onlyMembers{
        MySurvey.voteTo(projectid,choice,msg.sender);
    } 

    //for the winning projects? People vote the projects to get it paid, among the funded projects.
    function voteForProjectPayment(uint projectid,bool choice) public onlyMembers{  
        require(projects[projectid].funded,"Project is not funded!");
        MyFundingCampaign.approvalWithdrawal(projectid, choice); 
   }

    //7. Submitting Project Proposal costs 5 MyGov tokens and 0.1 Ether.Payable
    function submitProjectProposal(string ipfshash, uint votedeadline,uint [] paymentamounts, uint [] payschedule) public payable onlyMembers returns(uint projectid) {
        //require(getBalanceOf(msg.sender)>=5, "Proposal costs 5 MyGov Tokens");
        //require(msg.value>=0.1 ether,"Proposal costs 0.1 Ether");//0.1 ether = 100000000000000000 wei       
        donateEther();
        donateMyGovToken(5);
     
        projects[Id]=(Project({
        ipfsHash: ipfshash,
        voteDeadline: votedeadline,//deadline for the survey
        paymentAmounts: paymentamounts,//how much ether is needed 
        paySchedule: payschedule,//payments are scheduled
        recipient: msg.sender,//project proposer
        voteCount: 0,
        approvalCount: 0, //payment approvals count
        approved:false,
        funded:false
       // approvals:  //addresses who approve the 
            }));
        
        MySurvey.submitProposal(ipfshash, votedeadline/*, paymentamounts, payschedule*/,Id);
        Id++;
        //Id=MySurvey.getCountId();
        return Id;
    }

    bool public isSurveyDeployed;
    //8. Submittting Survey costs 2 MyGov tokens and 0.04 Ether.Payable
    function submitSurvey(string ipfshash,uint surveydeadline,uint numchoices, uint atmostchoice) public payable onlyMembers returns (address surveyid){
        //require(getBalanceOf(msg.sender)>=2, "Proposal costs 2 MyGov Tokens");
        //require(msg.value>=0.04 ether,"Proposal costs 0.04 Ether");//0.04 ether = 40000000000000000 wei
        donateEther();
        donateMyGovToken(5);
        isSurveyDeployed=true;
        MySurvey= new Survey(ipfshash,surveydeadline, numchoices, atmostchoice,msg.sender);
        emit SurveyAdresses(MySurvey);
        for(uint n=0; n<membersCount;n++){
        MySurvey.giveRightToVote(members[n]);}

        surveysCount++;
        return address(MySurvey); 
    }

    function takeSurvey(address surveyid,uint[] choices) public onlyMembers{
        Survey(surveyid).vote(choices,msg.sender);
    }
    
    function getSurveyResults(uint surveyid) public view returns(uint numtaken,uint[] resultsId, uint[] results) {

        numtaken=Survey(surveyid)._surveyNumchoices();
        (resultsId,results)=Survey(surveyid).getResults(numtaken);
        
        return(numtaken,resultsId,results);
    }

    function saveResults(uint numtaken,uint[] resultsId, uint[] results) public returns(bool){
        //get project informations and save the results
        for(uint i=0; i<numtaken; i++){
        Project storage proj = projects[resultsId[i]];
        proj.voteCount=results[i];
        }

    return true;
    }

    function endSurvey(uint surveyid) public returns(bool){ //End the survey manually and get the results (before the deadline)
        Survey(surveyid).sortByVotes();        
        (uint numtaken,uint[] memory resultsId,uint[] memory results)=getSurveyResults(surveyid);
        saveResults(numtaken,resultsId,results);
        for(uint i=0; i<Survey(surveyid).getSurveyAtmostchoice(); i++){
        if(checkIsProjectFunded(resultsId[i])==true){
        Project storage proj = projects[resultsId[i]];
        fundedProjectCount++;
        proj.funded=true;
        submitProjectCampaign(resultsId[i]);
        }
        }
        fundtransfer();
    return true;
    }

    function submitProjectCampaign(uint projectId) public {
    //Project memory proj = projects[projectId];
    MyFundingCampaign.createWithdrawal(projectId, projects[projectId].ipfsHash, projects[projectId].paymentAmounts, projects[projectId].paySchedule, projects[projectId].recipient);
    }

    function getSurveyInfo(uint surveyid) public view returns(string ipfshash, uint surveydeadline,uint numchoices, uint atmostchoice) {
        return (Survey(surveyid).getSurveyIpfshash(),
        Survey(surveyid).getSurveydeadline(),
        Survey(surveyid).getSurveyNumchoices(),
        Survey(surveyid).getSurveyAtmostchoice());
    }
    function getSurveyOwner(uint surveyid) public view returns(address surveyowner){
        return Survey(surveyid).chairperson();
    }

    function isSurveyDeployed() public view returns(bool){
        return isSurveyDeployed;}

/*
    //13.Project proposer must call reserveProjectGrant function in order to reserve the funding by the proposal deadline.
    //If the project proposer does not reserve by the deadline, funding is lost.
    //Also, if there is not sufficient ether in MyGov contract when trying to reserve, funding is lost.
    */
    function reserveProjectGrant(uint projectid) public{
        MyFundingCampaign.finalizeWithdrawal(projectid, membersCount);
    }

    function withdrawProjectPayment(uint projectid) public{
        MyFundingCampaign.cancel(projectid);
    }


    function checkIsProjectFunded(uint projectid) public view returns(bool funded){
        if(projects[projectid].voteCount >= membersCount/10 && projects[projectid].paymentAmounts[0] <= address(this).balance){
        return true;}
        else{
            return false;
        }
    }
    //13.In order to get a Project proposal funded, at least 1/10 of the members must vote yes AND there should be sufficient ether amount in the MyGov contract.
    function getIsProjectFunded(uint projectid) public view returns(bool funded){
        require(projects[projectid].voteCount >= membersCount/10, "At least 1/10 of the members must vote yes!");
        require(projects[projectid].paymentAmounts[0] <= address(this).balance, "There should be sufficient ether amount in the MyGov contract!");
        return true;
    }
   
   function divide() public view returns(uint){
       return membersCount/10;
   }
   
   function getContractBalance(address ContractAddress) public view returns(uint){
    return ContractAddress.balance;
}
   
   // function getProjectNextPayment(uint projectid) public view returns(int next)

    function getProjectOwner(uint projectid) public view returns(address projectowner){
        return (projects[projectid].recipient);
    }
    
    function getProjectInfo(uint projectid) public view returns(string ipfshash,uint votedeadline,uint [] paymentamounts, uint [] payschedule){
        //,address,uint,uint,bool,bool
        /*projects[projectid].recipient;//project proposer
        projects[projectid].voteCount;
        projects[projectid].approvalCount; //payment approvals count
        projects[projectid].approved;
        projects[projectid].funded;*/

        return (projects[projectid].ipfsHash,
        projects[projectid].voteDeadline,//deadline for the survey
        projects[projectid].paymentAmounts,//how much ether is needed 
        projects[projectid].paySchedule);//payments are scheduled)
    } 

    function getNoOfProjectProposals() public view returns(uint numproposals){
        return(Id);
    } 
    function getNoOfFundedProjects () public view returns(uint numfunded){
        return(fundedProjectCount);
    }

    //it should return total amount of money withdrawn.
    //function getEtherReceivedByProject (uint projectid) public view returns(uint tamount? amount){}    
    
    function getNoOfSurveys() public view returns(uint numsurveys){
        return(surveysCount);
    }



    }