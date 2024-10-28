// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

/**
 * @title StudyGroupPool
 * @dev A contract for managing a study group's pooled funds and voting on fund releases
 */
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
    event ProposalCreated(uint256 proposalId, string description, uint256 amount);
    event Voted(uint256 proposalId, address voter, bool inFavor);
    event ProposalExecuted(uint256 proposalId, bool passed);

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

    /**
     * @dev Add a new member to the study group
     * @param _member The address of the new member
     */
    function addMember(address _member) external onlyAdmin {
        require(!members[_member].isMember, "Already a member");
        members[_member].isMember = true;
        memberList.push(_member);
        totalMembers++;
        emit MemberAdded(_member);
    }

    /**
     * @dev Remove a member from the study group
     * @param _member The address of the member to remove
     */
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

    /**
     * @dev Contribute funds to the pool
     */
    function contributeFunds() external payable onlyMember {
        members[msg.sender].contribution += msg.value;
        totalFunds += msg.value;
        emit FundsContributed(msg.sender, msg.value);
    }

    /**
     * @dev Create a new proposal for fund release
     * @param _description Description of the proposal
     * @param _amount Amount of funds requested
     */
    function createProposal(string memory _description, uint256 _amount) external onlyMember {
        require(_amount <= totalFunds, "Requested amount exceeds available funds");
        uint256 proposalId = proposalCount++;
        Proposal storage newProposal = proposals[proposalId];
        newProposal.description = _description;
        newProposal.amount = _amount;
        emit ProposalCreated(proposalId, _description, _amount);
    }

    /**
     * @dev Vote on a proposal
     * @param _proposalId The ID of the proposal
     * @param _inFavor True if voting in favor, false if voting against
     */
    function vote(uint256 _proposalId, bool _inFavor) external onlyMember {
        Proposal storage proposal = proposals[_proposalId];
        require(!proposal.hasVoted[msg.sender], "Already voted on this proposal");
        require(!proposal.executed, "Proposal has already been executed");

        proposal.hasVoted[msg.sender] = true;
        if (_inFavor) {
            proposal.votesFor++;
        } else {
            proposal.votesAgainst++;
        }

        emit Voted(_proposalId, msg.sender, _inFavor);
    }

    /**
     * @dev Execute a proposal after the voting period
     * @param _proposalId The ID of the proposal to execute
     */
    function executeProposal(uint256 _proposalId) external onlyMember {
        Proposal storage proposal = proposals[_proposalId];
        require(!proposal.executed, "Proposal has already been executed");
        require(block.timestamp >= VOTING_PERIOD, "Voting period has not ended");

        uint256 totalVotes = proposal.votesFor + proposal.votesAgainst;
        uint256 quorum = (totalMembers * QUORUM_PERCENTAGE) / 100;

        require(totalVotes >= quorum, "Quorum not reached");

        proposal.executed = true;

        if (proposal.votesFor > proposal.votesAgainst && totalFunds >= proposal.amount) {
            totalFunds -= proposal.amount;
            payable(msg.sender).transfer(proposal.amount);
            emit ProposalExecuted(_proposalId, true);
        } else {
            emit ProposalExecuted(_proposalId, false);
        }
    }

    /**
     * @dev Get the details of a proposal
     * @param _proposalId The ID of the proposal
     * @return description The description of the proposal
     * @return amount The amount requested in the proposal
     * @return votesFor The number of votes in favor
     * @return votesAgainst The number of votes against
     * @return executed Whether the proposal has been executed
     */
    function getProposal(uint256 _proposalId) external view returns (
        string memory description,
        uint256 amount,
        uint256 votesFor,
        uint256 votesAgainst,
        bool executed
    ) {
        Proposal storage proposal = proposals[_proposalId];
        return (
            proposal.description,
            proposal.amount,
            proposal.votesFor,
            proposal.votesAgainst,
            proposal.executed
        );
    }

    /**
     * @dev Get the total number of members
     * @return The total number of members
     */
    function getMemberCount() external view returns (uint256) {
        return totalMembers;
    }

    /**
     * @dev Get the total funds in the pool
     * @return The total funds in wei
     */
    function getTotalFunds() external view returns (uint256) {
        return totalFunds;
    }
}