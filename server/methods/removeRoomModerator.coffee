Meteor.methods
	removeRoomModerator: (rid, userId) ->

		check rid, String
		check userId, String

		unless Meteor.userId()
			throw new Meteor.Error 'error-invalid-user', 'Invalid user', { method: 'removeRoomModerator' }

		unless RocketChat.authz.hasPermission Meteor.userId(), 'set-moderator', rid
			throw new Meteor.Error 'error-not-allowed', 'Not allowed', { method: 'removeRoomModerator' }

		user = RocketChat.models.Users.findOneById userId

		unless user?.username
			throw new Meteor.Error 'error-invalid-user', 'Invalid user', { method: 'removeRoomModerator' }

		subscription = RocketChat.models.Subscriptions.findOneByRoomIdAndUserId rid, user._id
		unless subscription?
			throw new Meteor.Error 'error-invalid-room', 'Invalid room', { method: 'removeRoomModerator' }

		if 'moderator' not in (subscription.roles or [])
			throw new Meteor.Error 'error-user-not-moderator', 'User is not a moderator', { method: 'removeRoomModerator' }

		RocketChat.models.Subscriptions.removeRoleById(subscription._id, 'moderator')

		fromUser = RocketChat.models.Users.findOneById Meteor.userId()
		RocketChat.models.Messages.createSubscriptionRoleRemovedWithRoomIdAndUser rid, user,
			u:
				_id: fromUser._id
				username: fromUser.username
			role: 'moderator'

		if RocketChat.settings.get('UI_DisplayRoles')
			RocketChat.Notifications.notifyAll('roles-change', { type: 'removed', _id: 'moderator', u: { _id: user._id, username: user.username }, scope: rid });

		return true
