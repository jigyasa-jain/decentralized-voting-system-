// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title Decentralized Voting System
 * @dev A transparent and secure voting system on the blockchain
 * @author Your Name
 */
contract Project {
    // Struct to represent a candidate
    struct Candidate {
        uint256 id;
        string name;
        uint256 voteCount;
        bool exists;
    }
    
    // Struct to represent a voter
    struct Voter {
        bool isRegistered;
        bool hasVoted;
        uint256 votedCandidateId;
    }
    
    // State variables
    address public owner;
    string public electionName;
    bool public votingActive;
    uint256 public totalVotes;
    uint256 public candidateCount;
    
    // Mappings
    mapping(uint256 => Candidate) public candidates;
    mapping(address => Voter) public voters;
    
    // Events
    event CandidateRegistered(uint256 indexed candidateId, string name);
    event VoterRegistered(address indexed voter);
    event VoteCasted(address indexed voter, uint256 indexed candidateId);
    event VotingStatusChanged(bool isActive);
    event ElectionResults(uint256 indexed winnerId, string winnerName, uint256 voteCount);
    
    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }
    
    modifier votingIsActive() {
        require(votingActive, "Voting is not currently active");
        _;
    }
    
    modifier votingIsInactive() {
        require(!votingActive, "Voting is currently active");
        _;
    }
    
    modifier onlyRegisteredVoter() {
        require(voters[msg.sender].isRegistered, "You are not registered to vote");
        _;
    }
    
    modifier hasNotVoted() {
        require(!voters[msg.sender].hasVoted, "You have already voted");
        _;
    }
    
    /**
     * @dev Constructor to initialize the voting system
     * @param _electionName Name of the election
     */
    constructor(string memory _electionName) {
        owner = msg.sender;
        electionName = _electionName;
        votingActive = false;
        totalVotes = 0;
        candidateCount = 0;
    }
    
    /**
     * @dev Core Function 1: Register a new candidate for the election
     * @param _name Name of the candidate to be registered
     */
    function registerCandidate(string memory _name) public onlyOwner votingIsInactive {
        require(bytes(_name).length > 0, "Candidate name cannot be empty");
        
        candidateCount++;
        candidates[candidateCount] = Candidate({
            id: candidateCount,
            name: _name,
            voteCount: 0,
            exists: true
        });
        
        emit CandidateRegistered(candidateCount, _name);
    }
    
    /**
     * @dev Core Function 2: Cast a vote for a candidate
     * @param _candidateId ID of the candidate to vote for
     */
    function vote(uint256 _candidateId) public votingIsActive onlyRegisteredVoter hasNotVoted {
        require(_candidateId > 0 && _candidateId <= candidateCount, "Invalid candidate ID");
        require(candidates[_candidateId].exists, "Candidate does not exist");
        
        // Record the vote
        voters[msg.sender].hasVoted = true;
        voters[msg.sender].votedCandidateId = _candidateId;
        
        // Increment candidate vote count
        candidates[_candidateId].voteCount++;
        totalVotes++;
        
        emit VoteCasted(msg.sender, _candidateId);
    }
    
    /**
     * @dev Core Function 3: Get election results and determine winner
     * @return winnerId ID of the winning candidate
     * @return winnerName Name of the winning candidate
     * @return winnerVoteCount Vote count of the winning candidate
     */
    function getElectionResults() public view returns (uint256 winnerId, string memory winnerName, uint256 winnerVoteCount) {
        require(candidateCount > 0, "No candidates registered");
        
        uint256 highestVoteCount = 0;
        uint256 currentWinnerId = 0;
        
        // Find candidate with highest vote count
        for (uint256 i = 1; i <= candidateCount; i++) {
            if (candidates[i].voteCount > highestVoteCount) {
                highestVoteCount = candidates[i].voteCount;
                currentWinnerId = i;
            }
        }
        
        if (currentWinnerId > 0) {
            return (
                currentWinnerId,
                candidates[currentWinnerId].name,
                candidates[currentWinnerId].voteCount
            );
        } else {
            return (0, "No winner yet", 0);
        }
    }
    
    // Additional utility functions
    
    /**
     * @dev Register a voter (only owner can register voters)
     * @param _voter Address of the voter to register
     */
    function registerVoter(address _voter) public onlyOwner {
        require(!voters[_voter].isRegistered, "Voter already registered");
        
        voters[_voter].isRegistered = true;
        voters[_voter].hasVoted = false;
        voters[_voter].votedCandidateId = 0;
        
        emit VoterRegistered(_voter);
    }
    
    /**
     * @dev Start or stop voting process
     * @param _status True to start voting, false to stop
     */
    function setVotingStatus(bool _status) public onlyOwner {
        votingActive = _status;
        emit VotingStatusChanged(_status);
    }
    
    /**
     * @dev Get candidate information by ID
     * @param _candidateId ID of the candidate
     * @return id Candidate ID
     * @return name Candidate name
     * @return voteCount Current vote count
     */
    function getCandidate(uint256 _candidateId) public view returns (uint256 id, string memory name, uint256 voteCount) {
        require(_candidateId > 0 && _candidateId <= candidateCount, "Invalid candidate ID");
        require(candidates[_candidateId].exists, "Candidate does not exist");
        
        Candidate memory candidate = candidates[_candidateId];
        return (candidate.id, candidate.name, candidate.voteCount);
    }
    
    /**
     * @dev Get voter information
     * @param _voter Address of the voter
     * @return isRegistered Whether voter is registered
     * @return hasVoted Whether voter has voted
     * @return votedCandidateId ID of candidate voted for (0 if not voted)
     */
    function getVoter(address _voter) public view returns (bool isRegistered, bool hasVoted, uint256 votedCandidateId) {
        Voter memory voter = voters[_voter];
        return (voter.isRegistered, voter.hasVoted, voter.votedCandidateId);
    }
    
    /**
     * @dev Get all candidates (for frontend display)
     * @return candidateIds Array of candidate IDs
     * @return candidateNames Array of candidate names
     * @return candidateVotes Array of candidate vote counts
     */
    function getAllCandidates() public view returns (
        uint256[] memory candidateIds,
        string[] memory candidateNames,
        uint256[] memory candidateVotes
    ) {
        candidateIds = new uint256[](candidateCount);
        candidateNames = new string[](candidateCount);
        candidateVotes = new uint256[](candidateCount);
        
        for (uint256 i = 1; i <= candidateCount; i++) {
            candidateIds[i-1] = candidates[i].id;
            candidateNames[i-1] = candidates[i].name;
            candidateVotes[i-1] = candidates[i].voteCount;
        }
        
        return (candidateIds, candidateNames, candidateVotes);
    }
}

