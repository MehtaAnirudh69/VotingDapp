// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

contract Voting {
    struct Candidate {
        string name;
        uint256 voteCount;
        address walletAddress;
    }

    address public owner;
    string public electionName;
    bool public electionActive;
    uint256 public votingEndTime;
    Candidate[] public candidates;
    mapping(address => bool) public hasVoted;
    mapping(address => bool) public isCandidate;

    event ElectionCreated(string electionName, uint256 durationInMinutes);
    event CandidateRegistered(string name, address walletAddress);
    event Voted(address voter, uint256 candidateIndex);
    event ElectionEnded();

    constructor() {
        owner = msg.sender;
        electionActive = false;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    modifier onlyDuringElection() {
        require(electionActive, "Election is not active.");
        require(block.timestamp < votingEndTime, "Voting period has ended.");
        _;
    }

    function createElection(
        string memory _electionName,
        string[] memory _candidateNames,
        uint256 _durationInMinutes
    ) public onlyOwner {
        require(!electionActive, "An election is already active.");
        require(
            _candidateNames.length >= 2,
            "At least two candidates are required."
        );

        delete candidates;
        electionName = _electionName;
        electionActive = true;
        votingEndTime = block.timestamp + (_durationInMinutes * 1 minutes);

        for (uint i = 0; i < _candidateNames.length; i++) {
            candidates.push(
                Candidate({
                    name: _candidateNames[i],
                    voteCount: 0,
                    walletAddress: address(0) // Placeholder, not used in this context
                })
            );
        }

        emit ElectionCreated(_electionName, _durationInMinutes);
    }

    function endElection() public onlyOwner {
        require(electionActive, "No active election to end.");
        electionActive = false;
        emit ElectionEnded();
    }

    function registerCandidate(string memory _name) public onlyDuringElection {
        require(!isCandidate[msg.sender], "You are already a candidate.");
        require(
            !hasVoted[msg.sender],
            "You have already voted and cannot register."
        );

        candidates.push(
            Candidate({name: _name, voteCount: 0, walletAddress: msg.sender})
        );
        isCandidate[msg.sender] = true;

        emit CandidateRegistered(_name, msg.sender);
    }

    function vote(uint256 _candidateIndex) public onlyDuringElection {
        require(
            _candidateIndex < candidates.length,
            "Invalid candidate index."
        );
        require(!hasVoted[msg.sender], "You have already voted.");
        require(!isCandidate[msg.sender], "Candidates cannot vote.");

        candidates[_candidateIndex].voteCount += 1;
        hasVoted[msg.sender] = true;

        emit Voted(msg.sender, _candidateIndex);
    }

    function getAllVotesOfCandiates() public view returns (Candidate[] memory) {
        return candidates;
    }

    function getElectionDetails() public view returns (string memory) {
        return electionName;
    }

    function getVotingStatus() public view returns (bool) {
        if (!electionActive) return false;
        return block.timestamp < votingEndTime;
    }

    function getRemainingTime() public view returns (uint256) {
        if (!electionActive || block.timestamp >= votingEndTime) return 0;
        return (votingEndTime - block.timestamp);
    }

    function getWinner()
        public
        view
        returns (string memory winnerName, uint256 winnerVotes)
    {
        require(
            !electionActive || block.timestamp >= votingEndTime,
            "Election is still active."
        );
        if (candidates.length == 0) return ("No candidates", 0);

        uint256 highestVotes = 0;
        string memory winner = "No votes yet";
        bool tie = false;

        for (uint i = 0; i < candidates.length; i++) {
            if (candidates[i].voteCount > highestVotes) {
                highestVotes = candidates[i].voteCount;
                winner = candidates[i].name;
                tie = false;
            } else if (
                candidates[i].voteCount == highestVotes && highestVotes > 0
            ) {
                tie = true;
            }
        }

        if (tie) return ("Tie", highestVotes);
        return (winner, highestVotes);
    }

    function isOwner() public view returns (bool) {
        return msg.sender == owner;
    }
}
