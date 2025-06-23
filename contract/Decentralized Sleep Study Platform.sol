// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title Decentralized Sleep Study Platform
 * @dev A blockchain-based platform for collecting sleep data and rewarding contributors
 * @author Sleep Study Team
 */
contract Project {
    // Token reward per valid sleep data submission
    uint256 public constant REWARD_PER_SUBMISSION = 10 * 10**18; // 10 tokens
    uint256 public constant MIN_SLEEP_HOURS = 1;
    uint256 public constant MAX_SLEEP_HOURS = 16;
    
    // Struct to store sleep data
    struct SleepData {
        uint256 timestamp;
        uint8 sleepHours;
        uint8 sleepQuality; // 1-10 scale
        uint8 stressLevel;  // 1-10 scale
        bool isVerified;
        address contributor;
    }
    
    // Struct to store user profile
    struct UserProfile {
        uint256 totalSubmissions;
        uint256 totalRewards;
        uint256 avgSleepHours;
        uint256 avgQuality;
        bool isActive;
        uint256 joinDate;
    }
    
    // State variables
    mapping(address => UserProfile) public userProfiles;
    mapping(uint256 => SleepData) public sleepRecords;
    mapping(address => uint256) public userBalances;
    
    uint256 public totalRecords;
    uint256 public totalRewardsDistributed;
    address public owner;
    
    // Events
    event SleepDataSubmitted(address indexed user, uint256 recordId, uint8 sleepHours, uint8 quality);
    event RewardClaimed(address indexed user, uint256 amount);
    event UserRegistered(address indexed user, uint256 timestamp);
    
    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    modifier onlyActiveUser() {
        require(userProfiles[msg.sender].isActive, "User must be registered and active");
        _;
    }
    
    constructor() {
        owner = msg.sender;
    }
    
    /**
     * @dev Core Function 1: Register User
     * @notice Allows users to register for the sleep study platform
     */
    function registerUser() external {
        require(!userProfiles[msg.sender].isActive, "User already registered");
        
        userProfiles[msg.sender] = UserProfile({
            totalSubmissions: 0,
            totalRewards: 0,
            avgSleepHours: 0,
            avgQuality: 0,
            isActive: true,
            joinDate: block.timestamp
        });
        
        emit UserRegistered(msg.sender, block.timestamp);
    }
    
    /**
     * @dev Core Function 2: Submit Sleep Data
     * @notice Allows registered users to submit their sleep data
     * @param _sleepHours Number of hours slept (1-16)
     * @param _sleepQuality Quality of sleep on scale 1-10
     * @param _stressLevel Stress level on scale 1-10
     */
    function submitSleepData(
        uint8 _sleepHours,
        uint8 _sleepQuality,
        uint8 _stressLevel
    ) external onlyActiveUser {
        require(_sleepHours >= MIN_SLEEP_HOURS && _sleepHours <= MAX_SLEEP_HOURS, "Invalid sleep hours");
        require(_sleepQuality >= 1 && _sleepQuality <= 10, "Sleep quality must be 1-10");
        require(_stressLevel >= 1 && _stressLevel <= 10, "Stress level must be 1-10");
        
        // Create new sleep record
        totalRecords++;
        sleepRecords[totalRecords] = SleepData({
            timestamp: block.timestamp,
            sleepHours: _sleepHours,
            sleepQuality: _sleepQuality,
            stressLevel: _stressLevel,
            isVerified: true, // Auto-verified for now, can be enhanced with oracles
            contributor: msg.sender
        });
        
        // Update user profile
        UserProfile storage profile = userProfiles[msg.sender];
        profile.totalSubmissions++;
        
        // Calculate new averages
        profile.avgSleepHours = ((profile.avgSleepHours * (profile.totalSubmissions - 1)) + _sleepHours) / profile.totalSubmissions;
        profile.avgQuality = ((profile.avgQuality * (profile.totalSubmissions - 1)) + _sleepQuality) / profile.totalSubmissions;
        
        // Award tokens
        userBalances[msg.sender] += REWARD_PER_SUBMISSION;
        profile.totalRewards += REWARD_PER_SUBMISSION;
        totalRewardsDistributed += REWARD_PER_SUBMISSION;
        
        emit SleepDataSubmitted(msg.sender, totalRecords, _sleepHours, _sleepQuality);
    }
    
    /**
     * @dev Core Function 3: Claim Rewards
     * @notice Allows users to claim their accumulated token rewards
     */
    function claimRewards() external onlyActiveUser {
        uint256 reward = userBalances[msg.sender];
        require(reward > 0, "No rewards to claim");
        
        userBalances[msg.sender] = 0;
        
        // In a real implementation, this would transfer actual tokens
        // For demo purposes, we emit an event
        emit RewardClaimed(msg.sender, reward);
    }
    
    // View functions for data analysis
    function getUserProfile(address _user) external view returns (UserProfile memory) {
        return userProfiles[_user];
    }
    
    function getSleepRecord(uint256 _recordId) external view returns (SleepData memory) {
        return sleepRecords[_recordId];
    }
    
    function getPlatformStats() external view returns (uint256, uint256, uint256) {
        return (totalRecords, totalRewardsDistributed, getTotalUsers());
    }
    
    function getTotalUsers() public pure returns (uint256) {
        // This is a simplified count - in production, you'd maintain a separate counter
        uint256 count = 0;
        // Note: This is not efficient for large datasets, would use enumerable sets in production
        return count;
    }
    
    // Emergency functions
    function pauseUser(address _user) external onlyOwner {
        userProfiles[_user].isActive = false;
    }
    
    function unpauseUser(address _user) external onlyOwner {
        userProfiles[_user].isActive = true;
    }
}
