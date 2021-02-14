## Discourse Auth0 Extension

> This Plugin is still a work in progress. We're building it based on various pieces of work we've done for clients on integrating Auth0 with Discourse. If you'd like to contribute to the plugin, or request specific features, please do so in our knowledge-base topic for this plugin: https://thepavilion.io/t/discourse-auth0-extension-plugin/4035.

This plugin contains Auth0-specific extensions to Discourse's user management. Each feature is described below.

### Auth0 Invites

This is an Auth0 implementation of bulk Discourse invites. This allows bulk invites to be made via the Discourse admin UI that are handled by Auth0. The users are send invite links which take them to Auth0 to finalise the process, before sending them back to Discourse.

The way it works is:

1. Admin uploads csv with invitee details in normal Discourse fashion.

2. On the server, the relevant method in the invites_controller is overridden in ``extensions/invites_controller.rb`` to process the invites via Auth0

3. The user details are sent to Auth0 for importation.

4. The job ``handle_auth0_invites.rb`` is run to generate a "Password Change" link for each user. This link will play the role of an invite link. There is no direct analog of a Discourse "invite link" that a user can click on to accept an invite in Auth0. The password change link can serve the same purpose if inserted into a invitation email. This approach is discussed in a few places on the Auth0 community forums.
   
Note: The ``invites_controller`` and ``handle_auth0_invites`` logic contains a few checks on the status on the import users job. This is necessary as that job is not synchronous and could possibly fail. This would mean the invite process would need to be aborted.
   
5. Once the users are imported into Auth0 and the invite links (i.e. the password change links) are obtained the invitees are sent invitation emails.

6. At this point the Admin who initiated the invite is given a report on their status (most likely all sent).

7. The invitee clicks on the password change link in their email (which is presented as an invitation link), they set a password and then they are directed to Discourse.

### Auth0 Silent Login

This is a way to "Automatically" log a user into Discourse if they have an existing session in Auth0, i.e. they have already logged in to Auth0 when using another application connected to the same tenant. It only works if Auth0 is the only authentication method, i.e. there are no other OAuth2 or OIDC methods, and both local logins and login by email are disabled.

Essentially how it works is that when a guest visits the site, they will be automatically redirected to auth0 login without needing to click on anything.