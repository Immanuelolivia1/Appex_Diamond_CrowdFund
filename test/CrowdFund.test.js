const {
    time,
    loadFixture,
  } = require("@nomicfoundation/hardhat-network-helpers");
  const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
  const { expect } = require("chai");
const { experimentalAddHardhatNetworkMessageTraceHook } = require("hardhat/config");

describe("CrowdFund.test",function(){
    async function deployCrowdFund(){
        const CrowdFund = await ethers.getContractFactory("CrowdFunding");

        const [deployer, addr1, addr2] = await ethers.getSigners();

        const crowdFund = await CrowdFund.deploy();
        // console.log(crowdFund)
        return {crowdFund, deployer, addr1, addr2}
    }

    describe("CrowdFund deployment", async() => {
        it("should have deployer as admin", async() => {
            const{crowdFund, deployer} = await loadFixture(deployCrowdFund);
            const admin = await crowdFund.admin();
            expect(deployer.address).to.equal(admin)
        }) 
        it("should have all state variables initialized as default", async() => {
            const{crowdFund} = await loadFixture(deployCrowdFund);

            const noOfCampaigns = await crowdFund.noOfCampaigns();
            const targetDonation = await crowdFund.targetDonation();
            const raisedAmount = await crowdFund.raisedAmount();
            const noOfDonators = await crowdFund.noOfDonators();

            expect(noOfCampaigns).to.equal(0)
            expect(targetDonation).to.equal(0)
            expect(raisedAmount).to.equal(0)
            expect(noOfDonators).to.equal(0)
        })
    })

    describe("Create Campaign", async() => {


        it("should emit the right events when someone creates a new campaign", async() => {

            const{crowdFund, deployer, addr1, addr2} = await loadFixture(deployCrowdFund);


           expect( await crowdFund.connect(addr1).createCampaign(
                "Balablu",
                addr1.address,
                10,
                1675180360
            )).to.emit(crowdFund, "CampaignCreated").withArgs(1)
        })
        it("should revert if arguments are wrong", async() =>{
            const{crowdFund, deployer, addr1, addr2} = await loadFixture(deployCrowdFund);
            expect(await crowdFund.connect(addr1).createCampaign(
                "Bulaba",
                addr2.address,
                10,
                1645180360
            )).to.be.reverted;

        })

        it("only Admin can approve campaing", async() =>{
            const{crowdFund, deployer, addr1, addr2} = await loadFixture(deployCrowdFund);
            (await crowdFund.connect(addr1).createCampaign(
                "Balablu",
                addr1.address,
                10,
                1675180360
            ))

            let campaign  = await crowdFund.Campaigns(1)
            expect(campaign.isApproved).to.eq(false)

            await crowdFund.connect(deployer).ApproveCampaign(1)

            campaign = await crowdFund.Campaigns(1)
            expect(campaign.isApproved).to.eq(true)
            

        })
        
        it("users should be able to donate to aproved campaigns", async() =>{
            const{crowdFund, deployer, addr1, addr2} = await loadFixture(deployCrowdFund);
            expect(await crowdFund.connect(addr2).Donate(
                1,
                addr2
            )).to.emit(crowdFund,"DonationRecieved").withArgs(3,1675180360)

        })
    })
});