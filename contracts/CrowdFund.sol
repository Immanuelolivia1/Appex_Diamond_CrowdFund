// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// [X] Anyone can create a campaign .
// [X] Get All project list
// [X] only admin can Approve campaigns
// [x] only approved campaigns can receive donations
// [x] owners can only withdraw when its deadline
// [x] @dev contract deducts 7% fee only when campaign target is met else campaign owner can withdraw total funds raised



contract CrowdFunding {

   
   
   uint public noOfCampaigns;
   uint public totalDonation;
   address public admin;
   uint ID = 1;
//    uint256 public deadline;
   uint256 public targetDonation; // required to reach at least this much amount
//    uint public completeAt;
   uint256 public raisedAmount; // Total raised amount till now
   uint256 public noOfDonators;
//    State public state = State.Fundraising;
   Campaign[] CampaignProjects;
   uint256 minContribution;
   uint256 public targetContribution;


   event CampaignCreated(uint id);
   event DonationRecieved(uint amount, uint when);
   event Withdrawal(uint amount, uint when);




   constructor() {
    admin = msg.sender;
   }

  enum State {
        Fundraising,
        Successful
  }
   struct Campaign {
    uint campaignID;
    uint noOfDonations;
    uint totalAmountDonated;
    uint campaignTarget;
    bool isApproved;
    string campaignName;
    address owner;
    State campaignState;
    uint campaignDeadline;
   }

   

   mapping (uint => Campaign) public Campaigns;
   mapping (address => uint) public donors;

   modifier onlyAdmin {
    require(msg.sender == admin, "Only admin can approve campaign"); 
    _;
   }

    // modifier validateExpiry(State _state){
    //     require(state == _state,'Invalid state');
    //     // require(block.timestamp < deadline,'Deadline has passed !');
    //     _;
    // }

    // @dev Anyone can start a fund rising
    // @dev return null
    function createCampaign(string memory _campaignName,
                            address _campaignOwner,
                            uint _campaignTarget,
                            uint _campaignDeadline)
    external {
    uint256 _id = ID;
    Campaign storage s = Campaigns[_id];

    s.campaignID = _id;
    s.campaignName = _campaignName;
    s.campaignTarget = _campaignTarget;
    s.noOfDonations = 0;
    s.totalAmountDonated = 0;
    s.owner = _campaignOwner;
    s.campaignState = State.Fundraising;
    s.campaignDeadline = _campaignDeadline;
    CampaignProjects.push(s);

    noOfCampaigns++;

    ID++;


    emit CampaignCreated(_id);
   }

    //@dev onlyAdmin can call this function
    //@return bool    
   function ApproveCampaign(uint _campaignID) external onlyAdmin {
    Campaign storage s = Campaigns[_campaignID];
    s.isApproved = true;
   }

// @dev any one can donate to a campaign
// @dev returns null
   function Donate(uint _campaignID, address _Donor) payable  external /*validateExpiry(State.Fundraising)*/ {

    Campaign storage s = Campaigns[_campaignID];
    require(msg.value > 0, "Please donate to this cause");
    // require(_campaignID > 000, "Please specify campaign to donate to");
    require(s.isApproved == true, "You can only donate to approved Campaigns");
    require(msg.value > 100 wei, "please you cant donate less than 100 wei");
    require(block.timestamp < s.campaignDeadline , "this campaign has expired");
    require(s.campaignState == State.Fundraising, "this campaign has expired");

    if(donors[_Donor] == 0){
            noOfDonators++;
        }
        donors[_Donor] += msg.value;
     
    s.noOfDonations++;
    s.totalAmountDonated += msg.value;
    totalDonation += msg.value;

    emit DonationRecieved(msg.value, block.timestamp);

   }

// @dev check if campaign is still on going or expired
// @return null
   function checkFundingCompleteOrExpire(uint _campaignId) internal view returns(bool) {
        bool status = false; 
        Campaign storage s = Campaigns[_campaignId];

        if(s.totalAmountDonated >= s.campaignTarget && block.timestamp > s.campaignDeadline && s.campaignState == State.Fundraising){
            status = true;
        }

        return status;
    }

   // @dev Get projects list
   // @return array
   function returnAllProjects() external view returns(Campaign[] memory ){
    return CampaignProjects;
   }

// @dev only CampaingnOwner can call this function 
// @dev owners can only withdraw when its deadline
// @dev contract deducts 7% fee only when campaign target is met else campaign owner can withdraw total funds raised
   function withdraw(uint _campaignID , address _campaignOwner) external {
    Campaign memory s = Campaigns[_campaignID];
    address _owner = s.owner;

    bool status = checkFundingCompleteOrExpire(_campaignID);

    require(_campaignOwner == _owner, "Only owner can withdraw");
    require(_owner != address(0), "invalid owner address");
    require(status == true, "withdraw not reached");

    uint amountToWithdraw;
    amountToWithdraw = s.totalAmountDonated;
    s.totalAmountDonated == 0;
    
    // if(s.totalAmountDonated < s.campaignTarget) {
    //   payable(_owner).transfer(amountToWithdraw);
    
      uint deduction;
      deduction = amountToWithdraw * 7/100;
      amountToWithdraw = amountToWithdraw - deduction;

      s.campaignState = State.Successful;

     payable(_owner).transfer(amountToWithdraw);
    

    emit Withdrawal(amountToWithdraw, block.timestamp);
   }
}