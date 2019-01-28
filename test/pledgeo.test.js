const Pledgeo = artifacts.require('Pledgeo')

contract('Pledgeo', function(accounts) {

    const owner = accounts[0]
    var communityId

    it("should pause the contract only if the caller is the contract owner", async () => {
        
        // Context: clean
        let instance = await Pledgeo.deployed()

        // Checks it does not pause the contract when the caller is not the contract owner 
        try {
            await instance.pause({from: accounts[1]})
            assert.fail('')
        }
        catch (error) {
            const revertFound = error.toString().search('revert')
            if (revertFound <= 0) {
                assert.fail(`Expected "revert", got ${error} instead`)
            }
        }

        // Checks it pauses the contract when the caller is the contract owner
        let eventEmittedTx1 = false
        let tx1 = await instance.pause({from: owner})
        if (tx1.logs[0].event) {
		    eventEmittedTx1 = true
        }
        let result1 = await instance.paused()
        assert.equal(eventEmittedTx1, true, 'pausing the contract should emit a Pause event')
        assert.equal(result1, true, 'the value of pause should be true')

        // Checks it unpauses the contract when the caller is the contract owner
        let eventEmittedTx2 = false
        let tx2 = await instance.unpause({from: owner})
        if (tx2.logs[0].event) {
		    eventEmittedTx2 = true
        }
        let result2 = await instance.paused()
        assert.equal(eventEmittedTx2, true, 'pausing the contract should emit a Pause event')
        assert.equal(result2, false, 'the value of pause should be false')
    })

    it("should add and remove a platform manager with the provided address and the proper caller restrictions", async() => {
        
        // Context: clean
        let instance = await Pledgeo.deployed()

        // Checks it doesn't add a new platform manager when the caller is not the contract owner
        try {
            await instance.addPlatformManager(accounts[1], {from: accounts[2]})
            assert.fail('')
        }
        catch (error) {
            const revertFound = error.toString().search('revert')
            if (revertFound <= 0) {
                assert.fail(`Expected "revert", got ${error} instead`)
            }
        }

        // Checks it adds a new platform manager when the caller is the contract owner
        let eventEmittedTx1 = false
	    let tx1 = await instance.addPlatformManager(accounts[1], {from: owner})
	    if (tx1.logs[0].event) {
		    eventEmittedTx1 = true
        }
        let result1 = await instance.platformManagers(accounts[1])
        assert.equal(eventEmittedTx1, true, 'adding a platform manager should emit a AddPlatformManager event')
        assert.equal(result1, true, 'the value of the mapping platform_manager for the key accounts[1] should be true')

        // Checks it doesn't remove a platform manager when the caller is not the contract owner
        try {
            await instance.removePlatformManager(accounts[1], {from: accounts[2]})
            assert.fail('')
        }
        catch (error) {
            const revertFound = error.toString().search('revert')
            if (revertFound <= 0) {
                assert.fail(`Expected "revert", got ${error} instead`)
            }
        }

        // Checks it removes a platform manager when the caller is the contract owner
        let eventEmittedTx2 = false
        let tx2 = await instance.removePlatformManager(accounts[1], {from: owner})
        if (tx2.logs[0].event) {
		    eventEmittedTx2 = true
        }
        let result2 = await instance.platformManagers(accounts[1])
        assert.equal(eventEmittedTx2, true, 'removing a platform manager should emit a AddPlatformManager event')
        assert.equal(result2, false, 'the value of the mapping platform_manager for the key accounts[1] should be false')
    })

    it("should add and remove a community with the provided parameters and the proper caller restrictions", async () => {
        
        // Context: accounts[1] is added as a platform manager
        let instance = await Pledgeo.deployed()
        await instance.addPlatformManager(accounts[1], {from: owner})

        // Checks it doesn't add a new community when the caller is not a platform manager
        try {
            await instance.addCommunity("description", {from: accounts[2]})
            assert.fail('')
        }
        catch (error) {
            const revertFound = error.toString().search('revert')
            if (revertFound <= 0) {
                assert.fail(`Expected "revert", got ${error} instead`)
            }
        }

        // Checks it adds a new community when the caller is a platform manager
        let eventEmittedTx1 = false
	    let tx1 = await instance.addCommunity("description", {from: accounts[1]})
        if (tx1.logs[0].event) {
            communityId = tx1.logs[0].args.communityId
		    eventEmittedTx1 = true
        }
        let result1 = await instance.communities(communityId)
        assert.equal(eventEmittedTx1, true, 'adding a community should emit a AddCommunity event')
        assert.equal(result1.valid, true, 'the value of the mapping communities for the key communityId should be true')

        // Checks it doesn't remove a community when the caller is not a platform manager
        try {
            await instance.removeCommunity(communityId, {from: accounts[2]})
            assert.fail('')
        }
        catch (error) {
            const revertFound = error.toString().search('revert')
            if (revertFound <= 0) {
                assert.fail(`Expected "revert", got ${error} instead`)
            }
        }

        // Checks it removes a community when the caller is a platform manager
        let eventEmittedTx2 = false
        let tx2 = await instance.removeCommunity(communityId, {from: accounts[1]})
        if (tx2.logs[0].event) {
		    eventEmittedTx2 = true
        }
        let result2 = await instance.communities(communityId)
        assert.equal(eventEmittedTx2, true, 'removing a community should emit a RemoveCommunity event')
        assert.equal(result2.valid, false, 'the value of the mapping communities for the key communityId and the parameter valid should be false')

    })

    it("should join a community with the provided parameters and the proper require restrictions", async () => {
        
        // Context: accounts[1] is added as a platform manager, a community is created and identified with communityId
        let instance = await Pledgeo.deployed()
        await instance.addPlatformManager(accounts[1], {from: owner})
        let contextTx = await instance.addCommunity("description", {from: accounts[1]})
        communityId = contextTx.logs[0].args.communityId

        // Checks it is not possible to join a community when the given identifier doesn't exist
        try {
            await instance.joinCommunity(communityId + 1, {from: accounts[2]})
            assert.fail('')
        }
        catch (error) {
            const revertFound = error.toString().search('revert')
            if (revertFound <= 0) {
                assert.fail(`Expected "revert", got ${error} instead`)
            }
        }

        // Checks it is possible to join a community when the given identifier exists
        let eventEmittedTx1 = false
	    let tx1 = await instance.joinCommunity(communityId, {from: accounts[2]})
        if (tx1.logs[0].event) {
		    eventEmittedTx1 = true
        }
        let result1 = await instance.communities(communityId)
        assert.equal(eventEmittedTx1, true, 'joining a community should emit a JoinCommunity event')
        assert.equal(result1.nbOfMembers, 1, 'the value of the mapping communities for the key communityId and the parameter ns_of_members should be 1')
    })

    it("should add and remove a business with the provided parameters and the proper caller restrictions", async () => {
        
        // Context: clean
        let instance = await Pledgeo.deployed()

        // Checks it adds a business
        let eventEmittedTx1 = false
        let tx1 = await instance.addBusiness("a description", {from: accounts[1]})
        if (tx1.logs[0].event) {
            businessId = tx1.logs[0].args.businessId
		    eventEmittedTx1 = true
        }
        let result1 = await instance.businesses(businessId)
        assert.equal(eventEmittedTx1, true, 'adding a business should emit a AddBusiness event')
        assert.equal(result1.owner, accounts[1], 'the value of the mapping businesses for the key businessId and parameter owner should be accounts[1]')

        // Checks it doesn't remove a business when the caller is not the business owner
        try {
            await instance.removeBusiness(businessId, {from: accounts[2]})
            assert.fail('')
        }
        catch (error) {
            const revertFound = error.toString().search('revert')
            if (revertFound <= 0) {
                assert.fail(`Expected "revert", got ${error} instead`)
            }
        }

        // Checks it removes a business when the caller is the business owner
        let eventEmittedTx2 = false
        let tx2 = await instance.removeBusiness(businessId, {from: accounts[1]})
        if (tx2.logs[0].event) {
		    eventEmittedTx2 = true
        }
        let result2 = await instance.businesses(businessId)
        assert.equal(eventEmittedTx2, true, 'removing a business should emit a AddBusiness event')
        assert.equal(result2.owner, false, 'the value of the mapping businesses for the key businessId and parameter owner should be false')

    })

    it("should add and remove a room with the provided parameters and the proper caller restrictions", async () => {
        
        // Context: accounts[1] is added as a platform manager, a community is created and identified with communityId
        // accounts[2] has joined the community
        let instance = await Pledgeo.deployed()
        await instance.addPlatformManager(accounts[1], {from: owner})
        let contextTx1 = await instance.addCommunity("a description", {from: accounts[1]})
        communityId = contextTx1.logs[0].args.communityId
        await instance.joinCommunity(communityId, {from: accounts[2]})

        // Checks it doesn't add a room when the caller is not a member of the community
        try {
            await instance.addRoom("a description", communityId, 3, {from: accounts[3]})
            assert.fail('')
        }
        catch (error) {
            const revertFound = error.toString().search('revert')
            if (revertFound <= 0) {
                assert.fail(`Expected "revert", got ${error} instead`)
            }
        }

        // Checks it adds a room when the caller is a member of the community
        let eventEmittedTx1 = false
	    let tx1 = await instance.addRoom("a description", communityId, 3, {from: accounts[2]})
        if (tx1.logs[0].event) {
            roomId = tx1.logs[0].args.roomId
		    eventEmittedTx1 = true
        }
        let result1 = await instance.rooms(roomId)
        assert.equal(eventEmittedTx1, true, 'adding a room should emit a AddRoom event')
        assert.equal(result1.owner, accounts[2], 'the value of the mapping rooms for the key roomId and parameter owner should be accounts[1]')

        // Checks it doesn't remove a room when the caller is not the owner of the room
        try {
            await instance.removeRoom(roomId, {from: accounts[3]})
            assert.fail('')
        }
        catch (error) {
            const revertFound = error.toString().search('revert')
            if (revertFound <= 0) {
                assert.fail(`Expected "revert", got ${error} instead`)
            }
        }

        // Checks it removes a room when the caller is the owner of the room
        let eventEmittedTx2 = false
        let tx2 = await instance.removeRoom(roomId, {from: accounts[2]})
        if (tx2.logs[0].event) {
		    eventEmittedTx2 = true
        }
        let result2 = await instance.rooms(roomId)
        assert.equal(eventEmittedTx2, true, 'removing a room should emit a AddRoom event')
        assert.equal(result2.owner, false, 'the value of the mapping rooms for the key roomId and parameter owner should be false')

    })

    it("should suggest an event with the provided parameters and the proper require restrictions", async () => {
        
        // Context: accounts[1] is added as a platform manager, a community is created and identified with communityId
        // accounts[2] and accounts[3] have joined the community, accounts[2] has added a room identified with roomId
        let instance = await Pledgeo.deployed()
        await instance.addPlatformManager(accounts[1], {from: owner})
        let contextTx1 = await instance.addCommunity("a description", {from: accounts[1]})
        communityId = contextTx1.logs[0].args.communityId
        await instance.joinCommunity(communityId, {from: accounts[2]})
        await instance.joinCommunity(communityId, {from: accounts[3]})
        let contextTx2 = await instance.addRoom("a description", communityId, 3, {from: accounts[2]})
        roomId = contextTx2.logs[0].args.roomId
        now = await instance.currentTime({from: accounts[1]})

        // Checks it is not possible to suggest an event when the caller is not part of the community
        participantPledge = 5
        try {
            await instance.suggestEvent("a description", communityId, roomId, now + 3, 1, 30, participantPledge, 3, now + 1, {value: participantPledge, from: accounts[4]})
            assert.fail('')
        }
        catch (error) {
            const revertFound = error.toString().search('revert')
            if (revertFound <= 0) {
                assert.fail(`Expected "revert", got ${error} instead`)
            }
        }

        // Checks it is not possible to suggest an event when the given room is not in the given community
        roomIdNotInCommunity = roomId + 1
        try {
            await instance.suggestEvent("a description", communityId, roomIdNotInCommunity, now + 3, 1, 30, participantPledge, 3, now + 1, {value: participantPledge, from: accounts[3]})
            assert.fail('')
        }
        catch (error) {
            const revertFound = error.toString().search('revert')
            if (revertFound <= 0) {
                assert.fail(`Expected "revert", got ${error} instead`)
            }
        }

        // Checks it is not possible to suggest an event when the ether attached doesn't match the given pledge
        participantPledge1 = 1
        participantPledge2 = 5
        try {
            await instance.suggestEvent("a description", communityId, roomId, now + 3, 1, 30, participantPledge1, 3, now + 1, {value: participantPledge2, from: accounts[3]})
            assert.fail('')
        }
        catch (error) {
            const revertFound = error.toString().search('revert')
            if (revertFound <= 0) {
                assert.fail(`Expected "revert", got ${error} instead`)
            }
        }

        // Checks it is possible to suggest an event when the given room is in the given community and the ether attached matches the given pledge
        let eventEmittedTx1 = false
	    let tx1 = await instance.suggestEvent("a description", communityId, roomId, now + 3, 1, 30, participantPledge, 3, now + 1, {value: participantPledge, from: accounts[3]})
        if (tx1.logs[0].event) {
            eventId = tx1.logs[0].args.eventId
		    eventEmittedTx1 = true
        }
        let result1 = await instance.events(eventId)
        assert.equal(eventEmittedTx1, true, 'suggesting an event should emit a SuggestEvent event')
        assert.equal(result1.nbOfParticipants, 1, 'the value of the mapping events for the key eventId and parameter nb_of_participant should be 1')
    })
    
    it("should join an event with the provided parameters and the proper require restrictions", async () => {
        
        // Context: similar to previous one, to which, accounts[4] is added as another member of the community
        let instance = await Pledgeo.deployed()
        await instance.joinCommunity(communityId, {from: accounts[4]})

        // Checks it is possible to join an even that was prealably suggested
        let eventEmittedTx1 = false
	    let tx1 = await instance.joinEvent(eventId, {value: participantPledge, from: accounts[4]})
        if (tx1.logs[0].event) {
		    eventEmittedTx1 = true
        }
        let result1 = await instance.events(eventId)
        assert.equal(eventEmittedTx1, true, 'joining an event should emit a JoinEvent event')
        assert.equal(result1.nbOfParticipants, 2, 'the value of the mapping events for the key eventId and parameter nb_of_participant should be 2')
    })
});
