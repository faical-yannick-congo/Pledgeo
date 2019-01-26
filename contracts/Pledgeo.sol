pragma solidity 0.5.0;

import "./Pausable.sol";

/**
 * @title Pledgeo
 * @author loic1
 * @notice You should use this contract for development purposes only
 * @dev Simple smart contract which allows to establich a platform that facilitates business in remote areas
 */
contract Pledgeo is Pausable {
    
    /* State variables */

    uint private communityId = 0;
    uint private businessId = 0;
    uint private roomId = 1;
    uint private eventId = 0;
    uint private complaintSubmissionDelay = 86400;

    mapping(uint => Community) public communities;
    mapping(uint => Business) public businesses;
    mapping(uint => Room) public rooms;
    mapping(uint => Event) public events;
    mapping(address => bool) public platformManagers;
    mapping(address => uint) private pendingWithdrawals;

    /* Structs and enums */

    struct Community {
        bool valid;
        string description;
        uint nbOfMembers;
        mapping(address => bool) members;
        uint[] events;
        mapping(uint => bool) rooms;
    }

    struct Business {
        address payable owner;
        string description;
    }

    struct Room {
        address payable owner;
        string description;
        uint compensationRate;
    }

    struct Event {
        State state;
        mapping(address => bool) participants;
        address payable [] listOfParticipants;
        string description;
        uint roomId;
        uint businessId;
        uint communityId;
        uint startDate;
        uint duration;
        uint businessOwnerPledge;
        uint participantPledge;
        uint minNbOfParticipants;
        uint nbOfParticipants;
        uint transportationCommissionRate;
        uint deadline;
        mapping(address => string) complaints;
    }

    enum State {Suggested, Submitted, Approved, Dropped, Cancelled, Disputed, Concluded}

    /* Modifiers */

    modifier onlyContractOwner() {
        require(contractOwner == msg.sender, "Only the contract owner can call this function");
        _;
    }
    modifier validCommunity(uint _communityId) {
        require(communities[_communityId].valid == true, "The community with the given id must be valid");
        _;
    }
    modifier onlyCommunityMember(uint _communityId) {
        require(communities[_communityId].members[msg.sender] == true, "Only a member of the given communityId can call this function");
        _;
    }
    modifier suggestedOrSubmittedEvent(uint _eventId) {
        require(events[_eventId].state == State.Suggested || events[_eventId].state == State.Submitted, "The event with the given _eventId must have the state Suggested or Submitted");
        _;
    }    
    modifier submittedOrApprovedEvent(uint _eventId) {
        require(events[_eventId].state == State.Submitted || events[_eventId].state == State.Approved, "The event with the given _eventId must have the state Submitted or Approved");
        _;
    }
    modifier suggestedEvent(uint _eventId) {
        require(events[_eventId].state == State.Suggested, "The event with the given _eventId must have the state Suggested");
        _;
    }
    modifier submittedEvent(uint _eventId) {
        require(events[_eventId].state == State.Submitted, "The event with the given _eventId must have the state Submitted");
        _;
    }
    modifier approvedEvent(uint _eventId) {
        require(events[_eventId].state == State.Approved, "The event with the given _eventId must have the state Approved");
        _;
    }
    modifier droppedEvent(uint _eventId) {
        require(events[_eventId].state == State.Dropped, "The event with the given _eventId must have the state Dropped");
        _;
    }
    modifier disputedEvent(uint _eventId) {
        require(events[_eventId].state == State.Disputed, "The event with the given _eventId must have the state Disputed");
        _;
    }
    modifier onlyPlatformManager() {
        require(platformManagers[msg.sender] == true, "Only community managers can call this function");
        _;
    }

    /* Events */

    event AddPlatformManager(address manager);
    event RemovePlatformManager(address manager);

    event AddCommunity(uint communityId, address indexed manager);
    event JoinCommunity(uint communityId, address member);
    event RemoveCommunity(uint communityId, address indexed manager);

    event AddBusiness(uint businessId);
    event RemoveBusiness(uint businessId); 

    event AddRoom(uint roomId);
    event RemoveRoom(uint roomId);

    event SuggestEvent(uint eventId);
    event AcceptEvent(uint eventId, uint businessId);
    event SubmitEvent(uint eventId);
    event JoinEvent(uint eventId, address participant);
    event CancelEvent(uint eventId);
    event LeaveEvent(uint eventId, address participant);
    event DropEvent(uint eventId);
    event ConcludeEvent(uint eventId);
    event SubmitComplaint(uint eventId, address complainant);
    event ConcludeEventWithComplaints(uint eventId, address indexed platformManager);

    /* Functions */

    /**
    * @dev Fallback function
    */
    function() external {
        revert("Fallback function");
    }

    /**
    * @dev addPlatformManager(): add an account to the list of platform managers
    * @param _manager address of the manager to add
    */
    function addPlatformManager(address _manager) external whenNotPaused onlyContractOwner {
        platformManagers[_manager] = true;
        emit AddPlatformManager(_manager);
    }

    /**
    * @dev removePlatformManager(): remove an account from the list of platform managers
    * @param _manager address of the manager to remove
    */
    function removePlatformManager(address _manager) external whenNotPaused onlyContractOwner {
        delete platformManagers[_manager];
        emit RemovePlatformManager(_manager);
    }

    /**
    * @dev addCommunity(): add a new Community
    * @param _description description of the Community to add (may include any necessary information like website links)
    */
    function addCommunity(string calldata _description) external whenNotPaused onlyPlatformManager {
        communities[communityId].valid = true;
        communities[communityId].description = _description;
        communities[communityId].nbOfMembers = 0;
        emit AddCommunity(communityId, msg.sender);
        communityId += 1;
    }

    /**
    * @dev joinCommunity(): join a Community
    * @param _communityId Community identifier
    */
    function joinCommunity(uint _communityId) external whenNotPaused validCommunity(_communityId) {
        communities[_communityId].members[msg.sender] = true;
        communities[_communityId].nbOfMembers += 1;
        emit JoinCommunity(_communityId, msg.sender);
    }

    /**
    * @dev removeCommunity(): remove a Community
    * @param _communityId Community identifier
    */    
    function removeCommunity(uint _communityId) external whenNotPaused onlyPlatformManager {
        delete communities[_communityId];
        emit RemoveCommunity(_communityId, msg.sender);
    }

    /**
    * @dev addBusiness(): add a new Business
    */ 
    function addBusiness(string calldata _description) external whenNotPaused { // string calldata _description
        businesses[businessId].owner = msg.sender;
        businesses[businessId].description = _description;
        emit AddBusiness(businessId);
        businessId += 1;
    }

    /**
    * @dev addBusiness(): add a new Business
    * @param _businessId Business identifier
    */ 
    function removeBusiness(uint _businessId) external whenNotPaused {
        require(businesses[_businessId].owner == msg.sender, "Only the owner can remove a business");
        delete businesses[_businessId];
        emit RemoveBusiness(_businessId);
    }

    /**
    * @dev addRoom(): add a new Room
    * @param _description description of the Room to add (may include any necessary information)
    * @param _communityId Community identifier
    * @param _compensationRate compensation rate of the pledge asked by the owner to provide their Room to the Community
    */ 
    function addRoom(
        string calldata _description,
        uint _communityId,
        uint _compensationRate
        )
        external
        whenNotPaused
        validCommunity(_communityId)
        onlyCommunityMember(_communityId) {

        rooms[roomId].owner = msg.sender;
        rooms[roomId].description = _description;
        rooms[roomId].compensationRate = _compensationRate;
        communities[_communityId].rooms[roomId] = true;
        emit AddRoom(roomId);
        roomId += 1;
    }

    /**
    * @dev removeRoom(): remove a Room
    * @param _roomId Room identifier
    */ 
    function removeRoom(uint _roomId) external whenNotPaused {
        require(rooms[_roomId].owner == msg.sender, "Only the owner can remove their room");
        delete rooms[_roomId];
        emit RemoveRoom(_roomId);
    }

    /**
    * @dev suggestEvent(): suggest a new Event
    * @param _description description of the Event (may include any necessary information like website links)
    * @param _communityId identifier of the Community to suggest the Event into
    * @param _roomId identifier of the Room the Event is set to take place into (0 is no room)
    * @param _startDate start date of the event in epoch seconds
    * @param _duration duration of the event in epoch seconds
    * @param _businessOwnerPledge amount of wei asked from the business owner
    * @param _participantPledge amount of wei asked from the participants
    * @param _transportationCommissionRate commission rate asked from the participants to secure the transportation cost reimbursement
    * @param _deadline end date for the event to be accepted by a business owner in epoch seconds
    */ 
    function suggestEvent(
        string calldata _description,
        uint _communityId,
        uint _roomId,
        uint _startDate,
        uint _duration,
        uint _businessOwnerPledge,
        uint _participantPledge,
        uint _transportationCommissionRate,
        uint _deadline
        )
        external
        payable
        whenNotPaused
        validCommunity(_communityId)
        onlyCommunityMember(_communityId) {
        
        require(now < _deadline && _deadline < _startDate, "Events can only be posted with a future deadline and start date");
        require(_businessOwnerPledge > _participantPledge, "Business owner pledge must be greater than participant pledge");
        require(_roomId == 0 || communities[_communityId].rooms[_roomId] == true, "The provided roomId should be either 0 (no room) or one added to the community");
        require(msg.value == _participantPledge, "The amount of ether attached to the function call must match the participant pledge");
        events[eventId].communityId = _communityId;
        communities[_communityId].events.push(eventId);
        events[eventId].description = _description;
        events[eventId].roomId = _roomId;
        events[eventId].startDate = _startDate;
        events[eventId].duration = _duration;
        events[eventId].businessOwnerPledge = _businessOwnerPledge;
        events[eventId].participantPledge = _participantPledge;
        events[eventId].nbOfParticipants = 1;
        events[eventId].transportationCommissionRate = _transportationCommissionRate;
        events[eventId].deadline = _deadline;
        events[eventId].participants[msg.sender] = true;
        events[eventId].listOfParticipants.push(msg.sender);
        events[eventId].state = State.Suggested;
        emit SuggestEvent(eventId);
        eventId += 1;
    }

    /**
    * @dev submitEvent(): submit a new Event
    * @param _description description of the Event (may include any necessary information like webite links)
    * @param _communityId identifier of the Community to suggest the Event into
    * @param _businessId identifier of the Business which submits the Event
    * @param _roomId identifier of the Room the Event is set to take place into (0 is no room)
    * @param _startDate start date of the event in epoch seconds
    * @param _duration duration of the event in epoch seconds
    * @param _businessOwnerPledge amount of wei asked from the business owner
    * @param _participantPledge amount of wei asked from the participants
    * @param _minNbOfParticipants minimum number of participants threshold for the Event state to be able to switch to Accepted
    * @param _transportationCommissionRate commission rate asked from the participants to secure the transportation cost reimbursement
    * @param _deadline end date for the event to be accepted by a business owner in epoch seconds
    */ 
    function submitEvent(
        string calldata _description,
        uint _communityId,
        uint _businessId,
        uint _roomId,
        uint _startDate,
        uint _duration,
        uint _businessOwnerPledge,
        uint _participantPledge,
        uint _minNbOfParticipants,
        uint _transportationCommissionRate,
        uint _deadline
        )
        external
        payable
        whenNotPaused
        validCommunity(_communityId) {
        
        require(businesses[_businessId].owner == msg.sender, "Only the owner of the given businessId can add an event associated to it");
        require(now < _deadline && _deadline < _startDate, "Events can only be posted with a future deadline and start date");
        require(_businessOwnerPledge > _participantPledge, "Business owner pledge must be greater than participant pledge");
        require(_roomId == 0 || communities[_communityId].rooms[_roomId] == true, "The provided roomId should be either 0 (no room) or one added to the community");
        require(msg.value == _businessOwnerPledge, "The amount of ether attached to the function call must match the business owner pledge");
        events[eventId].communityId = _communityId;
        communities[_communityId].events.push(eventId);
        events[eventId].description = _description;
        events[eventId].businessId = _businessId;
        events[eventId].roomId = _roomId;
        events[eventId].startDate = _startDate;
        events[eventId].duration = _duration;
        events[eventId].businessOwnerPledge = _businessOwnerPledge;
        events[eventId].participantPledge = _participantPledge;
        events[eventId].minNbOfParticipants = _minNbOfParticipants;
        events[eventId].nbOfParticipants = 0;
        events[eventId].transportationCommissionRate = _transportationCommissionRate;
        events[eventId].deadline = _deadline;
        events[eventId].state = State.Submitted;
        emit SubmitEvent(eventId);
        eventId += 1;
    }

    /**
    * @dev acceptEvent(): accept an Event
    * @param _eventId Event identifier
    * @param _businessId identifier of the Business which accepts the Event
    */ 
    function acceptEvent(uint _eventId, uint _businessId) external payable whenNotPaused suggestedEvent(_eventId) {
        require(businesses[_businessId].owner == msg.sender, "Only the owner of the given businessId can accept an event");        
        require(msg.value == events[_eventId].businessOwnerPledge, "The amount of ether attached to the function call must match the participant pledge");
        events[_eventId].businessId = _businessId;
        events[eventId].state = State.Approved;
        emit AcceptEvent(_eventId, _businessId);
    }

    /**
    * @dev getEvents(): get all the Events of a Community
    * @param _communityId Community identifier
    * @return _events identifiers of all the Events in the Community
    */ 
    function getEvents(
        uint _communityId
        )
        external
        view
        whenNotPaused
        validCommunity(_communityId)
        onlyCommunityMember(_communityId)
        returns(uint[] memory) {
        
        uint[] memory _events = communities[_communityId].events;
        return _events;
    }

    /**
    * @dev joinEvent(): join an Event
    * @param _eventId Event identifier
    */ 
    function joinEvent(uint _eventId) external payable whenNotPaused suggestedOrSubmittedEvent(_eventId) {
        require(communities[events[_eventId].communityId].members[msg.sender] == true, "");
        require(msg.value == events[_eventId].participantPledge, "The amount of ether attached to the function call must match the participant pledge");
        events[_eventId].participants[msg.sender] = true;
        events[_eventId].listOfParticipants.push(msg.sender);
        events[_eventId].nbOfParticipants += 1;
        if(events[eventId].state == State.Submitted && events[_eventId].listOfParticipants.length == events[_eventId].minNbOfParticipants) {
            events[eventId].state = State.Approved;
        }
        emit JoinEvent(_eventId, msg.sender);
    }

    /**
    * @dev cancelEvent(): cancel an Event
    * @param _eventId Event identifier
    */ 
    function cancelEvent(uint _eventId) external whenNotPaused submittedOrApprovedEvent(_eventId) {
        require(businesses[events[_eventId].businessId].owner == msg.sender, "An event can only be canceled by the business owner who added it");
        address payable [] memory listOfParticipants = events[_eventId].listOfParticipants;
        uint nbOfParticipants = listOfParticipants.length;
         //! division integer openzepellin safemath
        uint participantsRefund = events[_eventId].businessOwnerPledge / nbOfParticipants;
        for (uint i = 0; i < nbOfParticipants; i++) {
            pendingWithdrawals[listOfParticipants[i]] += participantsRefund;
        }
        events[_eventId].state = State.Cancelled;
        emit CancelEvent(_eventId);
    }

    /**
    * @dev leaveEvent(): leave an Event
    * @param _eventId Event identifier
    */ 
    function leaveEvent(uint _eventId) external whenNotPaused submittedOrApprovedEvent(_eventId) {
        require(events[_eventId].participants[msg.sender] == true, "Only a participant can leave an event they joined");
        pendingWithdrawals[businesses[events[_eventId].businessId].owner] += events[_eventId].participantPledge;
        emit LeaveEvent(_eventId, msg.sender);
    }

    /**
    * @dev dropEvent(): drop an Event (may be called by anyone, in particular, it could be automated using Oraclize or Ethereum Alarm Clock))
    * @param _eventId Event identifier
    */
    function dropEvent(uint _eventId) external whenNotPaused approvedEvent(_eventId) {
        require(now > events[_eventId].deadline && events[_eventId].listOfParticipants.length < events[_eventId].minNbOfParticipants, "Events can only be dropped once the deadline passed and there are not enough participants"); 
        pendingWithdrawals[businesses[events[_eventId].businessId].owner] += events[_eventId].businessOwnerPledge;
        address payable [] memory listOfParticipants = events[_eventId].listOfParticipants;
        uint nbOfParticipants = listOfParticipants.length;
        uint participantsRefund = events[_eventId].participantPledge;
        for (uint i = 0; i < nbOfParticipants; i++) {
            pendingWithdrawals[listOfParticipants[i]] += participantsRefund;
        }
        events[_eventId].state = State.Dropped;
        emit DropEvent(_eventId);
    } 

    /**
    * @dev concludeEvent(): conclude an Event (may be called by anyone, in particular, it could be automated using Oraclize or Ethereum Alarm Clock))
    * @param _eventId Event identifier
    */
    function concludeEvent(uint _eventId) external whenNotPaused approvedEvent(_eventId) {
        require(now >= events[_eventId].startDate + events[_eventId].duration + complaintSubmissionDelay, "Events can only be validated once they started");
        address payable [] memory listOfParticipants = events[_eventId].listOfParticipants;
        uint nbOfParticipants = listOfParticipants.length;
        if (roomId != 0) {
            pendingWithdrawals[rooms[events[_eventId].roomId].owner] += rooms[events[_eventId].roomId].compensationRate * events[_eventId].participantPledge * nbOfParticipants;
            uint participantsRefund = (1 - events[_eventId].transportationCommissionRate - rooms[events[_eventId].roomId].compensationRate) * events[_eventId].participantPledge;
            for (uint i = 0; i < nbOfParticipants; i++) {
                pendingWithdrawals[listOfParticipants[i]] += participantsRefund;
            }
            pendingWithdrawals[businesses[events[_eventId].businessId].owner] += events[_eventId].businessOwnerPledge + (events[_eventId].transportationCommissionRate - rooms[events[_eventId].roomId].compensationRate) * events[_eventId].participantPledge * nbOfParticipants;
        }
        else {
            uint participantsRefund = (1 - events[_eventId].transportationCommissionRate) * events[_eventId].participantPledge; 
            for (uint i = 0; i < nbOfParticipants; i++) {
                pendingWithdrawals[listOfParticipants[i]] += participantsRefund;
            }
            pendingWithdrawals[businesses[events[_eventId].businessId].owner] += events[_eventId].businessOwnerPledge + events[_eventId].transportationCommissionRate * events[_eventId].participantPledge * nbOfParticipants;
        }
        events[_eventId].state = State.Concluded;  
        emit ConcludeEvent(_eventId);
    }

    /**
    * @dev submitComplaint(): submit a complaint about an Event
    * @param _eventId Event identifier
    * @param _description description of the complaint (may include any necessery information)
    */
    function submitComplaint(uint _eventId, string calldata _description) external whenNotPaused approvedEvent(_eventId) {
        require(events[_eventId].participants[msg.sender] == true || businesses[events[_eventId].businessId].owner == msg.sender, "Only a participant or the business owner can submit a complaint");
        events[_eventId].complaints[msg.sender] = _description;
        if (events[_eventId].state != State.Disputed) {
            events[_eventId].state = State.Disputed;
        }
        emit SubmitComplaint(_eventId, msg.sender);
    }

    /**
    * @dev concludeEventWithComplaints(): conclude a disputed Event
    * @param _eventId Event identifier
    * @param _participantRefunds list of the amounts in wei each partiipant will be refunded with
    * @param _businessOwnerRefund amount in wei the business owner will be refunded with
    * @param _roomOwnerRefund amount in wei the room owner will be refunded with
    */
    function concludeEventWithComplaints(
        uint _eventId,
        uint[] calldata _participantRefunds,
        uint _businessOwnerRefund,
        uint _roomOwnerRefund
        )
        external
        whenNotPaused
        onlyPlatformManager
        disputedEvent(_eventId) {
        
        uint nbOfParticipants = events[_eventId].listOfParticipants.length;
        uint totalParticipantsRefund = 0;
        for (uint i = 0; i < nbOfParticipants; i++) {
            totalParticipantsRefund += _participantRefunds[i];
        }
        require(totalParticipantsRefund + _businessOwnerRefund + _roomOwnerRefund == events[_eventId].listOfParticipants.length * events[_eventId].participantPledge + events[_eventId].businessOwnerPledge, "");
        for (uint i = 0; i < nbOfParticipants; i++) {
            pendingWithdrawals[events[_eventId].listOfParticipants[i]] += _participantRefunds[i];
        }
        pendingWithdrawals[businesses[events[_eventId].businessId].owner] += _businessOwnerRefund;
        if (roomId != 0) {
            pendingWithdrawals[rooms[events[_eventId].roomId].owner] += _roomOwnerRefund;
        }
        events[_eventId].state = State.Concluded;
        emit ConcludeEventWithComplaints(_eventId, msg.sender);
    }

    /**
    * @dev withdrawBalance(): withdraw the account's available balance
    */
    function withdrawalance() public {
        uint amount = pendingWithdrawals[msg.sender];
        pendingWithdrawals[msg.sender] = 0;
        msg.sender.transfer(amount);
    }

    /**
    * @dev currentTime(): Functions used for Javascript tests
    * @return time in epoch seconds
    */
    function currentTime() external view returns (uint256 _currentTime) {
        return now;
    }
}