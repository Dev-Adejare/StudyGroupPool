// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

contract StudyGroupPool {
    struct Member {
        bool isMember;
        uint256 contribution;
    }

    struct Proposal {
        string description;
        uint256 amount;
        uint256 votesFor;
        uint256 votesAgainst;
        bool executed;
        uint256 creationTime;
        address payable beneficiary;
        mapping(address => bool) hasVoted;
    }

    address public admin;
    mapping(address => Member) public members;
    address[] public memberList;
    uint256 public totalMembers;
    uint256 public totalFunds;
    uint256 public proposalCount;
    mapping(uint256 => Proposal) public proposals;

    uint256 public constant VOTING_PERIOD = 3 days;
    uint256 public constant QUORUM_PERCENTAGE = 50;

    event MemberAdded(address member);
    event MemberRemoved(address member);
    event FundsContributed(address member, uint256 amount);
    event FundsWithdrawn(address member, uint256 amount);
    event ProposalCreated(uint256 proposalId, string description, uint256 amount, address beneficiary);
    event Voted(uint256 proposalId, address voter, bool inFavor);
    event ProposalExecuted(uint256 proposalId, bool passed, uint256 amount, address beneficiary);

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action");
        _;
    }

    modifier onlyMember() {
        require(members[msg.sender].isMember, "Only members can perform this action");
        _;
    }

    constructor() {
        admin = msg.sender;
    }

    // ######## Add a new member to the study group #########/

    function addMember(address _member) external onlyAdmin {
        require(!members[_member].isMember, "Already a member");
        members[_member].isMember = true;
        memberList.push(_member);
        totalMembers++;
        emit MemberAdded(_member);
    }

    // /########## Remove a member from the study group ########/

    function removeMember(address _member) external onlyAdmin {
        require(members[_member].isMember, "Not a member");
        members[_member].isMember = false;
        for (uint i = 0; i < memberList.length; i++) {
            if (memberList[i] == _member) {
                memberList[i] = memberList[memberList.length - 1];
                memberList.pop();
                break;
            }
        }
        totalMembers--;
        emit MemberRemoved(_member);
    }

    
    //####### Contribute funds to the pool ##########

    function contributeFunds() external payable onlyMember {
        members[msg.sender].contribution += msg.value;
        totalFunds += msg.value;
        emit FundsContributed(msg.sender, msg.value);
    }

    //  ##########   Withdraw contributed funds #######
    
    function withdrawFunds(uint256 _amount) external onlyMember {
        require(members[msg.sender].contribution >= _amount, "Insufficient contribution");
        members[msg.sender].contribution -= _amount;
        totalFunds -= _amount;
        (bool success, ) = msg.sender.call{value: _amount}("");
        require(success, "Transfer failed");
        emit FundsWithdrawn(msg.sender, _amount);
    }

    /**##### Create a new proposal for fund release #######     */

    function createProposal(string memory _description, uint256 _amount, address payable _beneficiary) external onlyMember {
        require(_amount <= totalFunds, "Requested amount exceeds available funds");
        uint256 proposalId = proposalCount++;
        Proposal storage newProposal = proposals[proposalId];
        newProposal.description = _description;
        newProposal.amount = _amount;
        newProposal.creationTime = block.timestamp;
        newProposal.beneficiary = _beneficiary;
        emit ProposalCreated(proposalId, _description, _amount, _beneficiary);
    }

    /*####### Vote on a proposal  ##########*/

    function vote(uint256 _proposalId, bool _inFavor) external onlyMember {
        Proposal storage proposal = proposals[_proposalId];
        require(!proposal.hasVoted[msg.sender], "Already voted on this proposal");
        require(!proposal.executed, "Proposal has already been executed");
        require(block.timestamp < proposal.creationTime + VOTING_PERIOD, "Voting period has ended");

        proposal.hasVoted[msg.sender] = true;
        if (_inFavor) {
            proposal.votesFor++;
        } else {
            proposal.votesAgainst++;
        }

        emit Voted(_proposalId, msg.sender, _inFavor);
    }

    /**####### Execute a proposal after the voting period ########*/

    function executeProposal(uint256 _proposalId) external onlyMember {
        Proposal storage proposal = proposals[_proposalId];
        require(!proposal.executed, "Proposal has already been executed");
        require(block.timestamp >= proposal.creationTime + VOTING_PERIOD, "Voting period has not ended");

        uint256 totalVotes = proposal.votesFor + proposal.votesAgainst;
        uint256 quorum = (totalMembers * QUORUM_PERCENTAGE) / 100;

        require(totalVotes >= quorum, "Quorum not reached");

        proposal.executed = true;

        if (proposal.votesFor > proposal.votesAgainst && totalFunds >= proposal.amount) {
            totalFunds -= proposal.amount;
            (bool success, ) = proposal.beneficiary.call{value: proposal.amount}("");
            require(success, "Transfer failed");
            emit ProposalExecuted(_proposalId, true, proposal.amount, proposal.beneficiary);
        } else {
            emit ProposalExecuted(_proposalId, false, 0, proposal.beneficiary);
        }
    }

    /*##### Get the details of a proposal #####*/

    function getProposal(uint256 _proposalId) external view returns (
        string memory description,
        uint256 amount,
        uint256 votesFor,
        uint256 votesAgainst,
        bool executed,
        uint256 creationTime,
        address beneficiary
    ) {
        Proposal storage proposal = proposals[_proposalId];
        return (
            proposal.description,
            proposal.amount,
            proposal.votesFor,
            proposal.votesAgainst,
            proposal.executed,
            proposal.creationTime,
            proposal.beneficiary
        );
    }

    /*######  Get the total number of members #####    */

    function getMemberCount() external view returns (uint256) {
        return totalMembers;
    }

    /*######### Get the total funds in the pool #### */

    function getTotalFunds() external view returns (uint256) {
        return totalFunds;
    }

    /*####### Get a member's contribution #######*/

    function getMemberContribution(address _member) external view returns (uint256) {
        return members[_member].contribution;
    }
}