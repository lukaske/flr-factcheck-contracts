// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract FlareFactChecker {
    address public owner;
    address public aggregator;
    uint256 public verificationFee;
    
    struct VerificationRequest {
        address requester;
        string text;
        uint256 timestamp;
        bool isComplete;
        string aggregateResult;
        mapping(address => string) verifierResults;
        address[] verifiers;
    }
    
    mapping(uint256 => VerificationRequest) public requests;
    uint256 public requestCount;
    
    // Authorized verifiers
    mapping(address => bool) public authorizedVerifiers;
    
    event RequestSubmitted(uint256 requestId, address requester, string text);
    event VerificationResultSubmitted(uint256 requestId, address verifier, string result);
    event AggregateResultSubmitted(uint256 requestId, string aggregateResult);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    modifier onlyAggregator() {
        require(msg.sender == aggregator, "Only aggregator can call this function");
        _;
    }
    
    modifier onlyVerifier() {
        require(authorizedVerifiers[msg.sender], "Only authorized verifiers can call this function");
        _;
    }
    
    constructor(uint256 _fee, address _aggregator) {
        owner = msg.sender;
        verificationFee = _fee;
        aggregator = _aggregator;
    }
    
    function submitRequest(string calldata _text) external payable returns (uint256) {
        require(msg.value >= verificationFee, "Insufficient fee");
        
        uint256 requestId = requestCount++;
        
        VerificationRequest storage newRequest = requests[requestId];
        newRequest.requester = msg.sender;
        newRequest.text = _text;
        newRequest.timestamp = block.timestamp;
        newRequest.isComplete = false;
        
        emit RequestSubmitted(requestId, msg.sender, _text);
        return requestId;
    }
    
    function submitVerification(uint256 _requestId, string calldata _result) external onlyVerifier {
        VerificationRequest storage request = requests[_requestId];
        require(!request.isComplete, "Request already completed");
        
        // Add the verifier to the list if not already added
        bool verifierExists = false;
        for (uint i = 0; i < request.verifiers.length; i++) {
            if (request.verifiers[i] == msg.sender) {
                verifierExists = true;
                break;
            }
        }
        
        if (!verifierExists) {
            request.verifiers.push(msg.sender);
        }
        
        request.verifierResults[msg.sender] = _result;
        emit VerificationResultSubmitted(_requestId, msg.sender, _result);
    }
    
    function submitAggregateResult(uint256 _requestId, string calldata _aggregateResult) external onlyAggregator {
        VerificationRequest storage request = requests[_requestId];
        require(!request.isComplete, "Request already completed");
        
        request.aggregateResult = _aggregateResult;
        request.isComplete = true;
        
        emit AggregateResultSubmitted(_requestId, _aggregateResult);
    }
    
    function addVerifier(address _verifier) external onlyOwner {
        authorizedVerifiers[_verifier] = true;
    }
    
    function removeVerifier(address _verifier) external onlyOwner {
        authorizedVerifiers[_verifier] = false;
    }
    
    function setAggregator(address _aggregator) external onlyOwner {
        aggregator = _aggregator;
    }
    
    function setVerificationFee(uint256 _fee) external onlyOwner {
        verificationFee = _fee;
    }
    
    function getVerifierResult(uint256 _requestId, address _verifier) external view returns (string memory) {
        return requests[_requestId].verifierResults[_verifier];
    }
    
    function getVerifiersForRequest(uint256 _requestId) external view returns (address[] memory) {
        return requests[_requestId].verifiers;
    }
    
    function withdrawFees() external onlyOwner {
        payable(owner).transfer(address(this).balance);
    }
}