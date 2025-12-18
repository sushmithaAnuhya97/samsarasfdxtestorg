trigger FeedItemTrigger on FeedItem (before insert) {
    new FeedItemTriggerHandler().run();
	/*for (FeedItem feeditem : Trigger.new)
    {
        system.debug('feeditem ' + feeditem);
        if(feeditem.Visibility!='InternalUsers')
        feeditem.addError('Please use Samsara Only Option to tag internal user within Samsara');
    }
	*/	
    //For each FeedItem record:
    //Check if the FeedItem is for an allowed group
    //Check if the FeedItem is for the allowed Community

    //if (!allowedGroups.containsKey(feeditem) && feeditems.NetworkScope== '0DBB000000008t2OAA'){

      //Add the error to the feeditem
      
    //}
}