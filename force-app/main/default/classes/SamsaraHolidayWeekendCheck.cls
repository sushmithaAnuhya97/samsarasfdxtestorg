/**********************************************************************
Name: SamsaraHolidayWeekendCheck
TestClass: SamsaraHolidayWeekendCheckTest
=======================================================================
Purpose: This class check SamasaraHoliday and Weekends 
and this service is consumed in Quote Approval Deal Desk Email flow
=======================================================================
History  

VERSION     AUTHOR               DATE               DETAIL                       
1.0        Chetan Basavaraju   2023-Nov-06        FOR GTMS-15662

***********************************************************************/ 
public class SamsaraHolidayWeekendCheck {
    public static List<Holiday> holidays = new List<Holiday>();
    public static Map<String, BusinessHours> businessHoursMap = new Map<String, BusinessHours>();
    
    public SamsaraHolidayWeekendCheck(string countryName) {
        holidays=[Select h.StartTimeInMinutes, h.Name, h.ActivityDate From Holiday h limit 200];
        List<BusinessHours> listBusinessHours = [Select Id,Name,
                                                 SundayStartTime, MondayStartTime, TuesdayStartTime,
                                                 WednesdayStartTime, ThursdayStartTime, FridayStartTime,
                                                 SaturdayStartTime, SundayEndTime, MondayEndTime,TuesdayEndTime,
                                                 WednesdayEndTime, ThursdayEndTime, FridayEndTime,SaturdayEndTime
                                                 From BusinessHours 
                                                 Where Name =:countryName];
        FOR(BusinessHours bhRec : listBusinessHours) {
            businessHoursMap.put(bhRec.Name, bhRec);
        }
    }
    
    @InvocableMethod public static List<Boolean> isSamasaraHolidayOrWeekend(List<Date> datesToCheck){ 
        Boolean isHolidayOrWeekend = false;
        DateTime todayDate = DateTime.newInstance(datesToCheck[0], Time.newInstance(0,0,0,0));
        String dayOfWeek = todayDate.format('E'); // dayOfWeek is Sun, Mon, Tue, etc.
        
        if(dayOfWeek.equalsIgnoreCase('Sat') || dayOfWeek.equalsIgnoreCase('Sun')){
            isHolidayOrWeekend = true;
        } else {
            isHolidayOrWeekend = isHoliday(todayDate);
        }
        return new List<Boolean>{isHolidayOrWeekend};
    }
    
    public static Boolean isSamasaraHolidayOrWeekend(Date datesToCheck){ 
        Boolean isHolidayOrWeekend = false;
        DateTime todayDate = DateTime.newInstance(datesToCheck, Time.newInstance(0,0,0,0));
        String dayOfWeek = todayDate.format('E'); // dayOfWeek is Sun, Mon, Tue, etc.
        
        if(dayOfWeek.equalsIgnoreCase('Sat') || dayOfWeek.equalsIgnoreCase('Sun')){
            isHolidayOrWeekend = true;
        } else {
            isHolidayOrWeekend = isHoliday(todayDate);
        }
        return isHolidayOrWeekend;
    }
    
    public static boolean isHoliday(DateTime inDateToBeChecked) {
        if (holidays.size()==0)
            holidays=[Select h.StartTimeInMinutes, h.Name, h.ActivityDate From Holiday h limit 50];
        // check if current day is holiday or not
        Boolean isDateHoliday = false;
        for(Holiday dateHoliday : holidays) {
            //system.debug('inDateToBeChecked. ' + inDateToBeChecked.dateGMT());
            //system.debug('dateHoliday.ActivityDate. ' + dateHoliday.ActivityDate);
            if(dateHoliday.ActivityDate == inDateToBeChecked.dateGMT()) {
                isDateHoliday = true;
                break;
            }
            
        }
        return isDateHoliday;
    }
    /*
     * logic that calculates the date which will be used as the starting point of a query
     * */
    public DateTime determineStartDateTime(DateTime inStartDateTime) {
        DateTime dateTimeValue = inStartDateTime;
        Boolean isNotHolidayOrWeekend = true;
        Integer dayCounter = 1;
        while (isNotHolidayOrWeekend) {
            String dayOfWeek = null;
            DateTime tempDateTimeValue;
            tempDateTimeValue = inStartDateTime - dayCounter;
            dayOfWeek = tempDateTimeValue.format('E'); // dayOfWeek is Sun, Mon, Tue, etc.
        	
            Boolean isHolidayValue = isHoliday(tempDateTimeValue);
            if (!dayOfWeek.equalsIgnoreCase('Sat') && !dayOfWeek.equalsIgnoreCase('Sun') && !isHolidayValue) {
                isNotHolidayOrWeekend = false;
                dateTimeValue = tempDateTimeValue;
                break;
            }
            dayCounter=dayCounter+1;
            
        }
        
        return dateTimeValue;
    }
    
    /*
     * performs the logic to check if the email is to be sent
     * */
    public boolean isEmailAlertToBeSent(string countryName, string timeZoneName, DateTime recordLastModifiedDate) {
    	Boolean sendAlert = false;
        Time curreEndTime = null;
        Time curreStartTime = null;
        Datetime currGMTDate = system.now();
        //currGMTDate = DateTime.newInstance(2023, 11, 27, 15, 3, 3);
        String strCurrConvertedDate = 
            currGMTDate.format('MM/dd/yyyy HH:mm:ss', 
                           timeZoneName);
        Datetime GMTDate = recordLastModifiedDate;
        String strConvertedDate = 
            GMTDate.format('MM/dd/yyyy HH:mm:ss', 
                           timeZoneName);
        system.debug('strConvertedDate ' + strConvertedDate);
        integer lastModifiedHour = integer.valueOf(strConvertedDate.substring(11,13));
        integer currSystemHour = integer.valueOf(strCurrConvertedDate.substring(11,13));
        integer recordLastModifiedDay = recordLastModifiedDate.day();
        
        // check if last modified or weekends
        if (isSamasaraHolidayOrWeekend(recordLastModifiedDate.date())) {
            recordLastModifiedDay = currGMTDate.day();
            lastModifiedHour = 9;
            recordLastModifiedDate = currGMTDate;
        }
        
        // get start time
		curreStartTime = getDayEndTime(true, countryName, recordLastModifiedDate, timeZoneName);
        
        // get end time
        curreEndTime = getDayEndTime(false, countryName, recordLastModifiedDate, timeZoneName);
        
        /*system.debug('currGMTDate.day() ' + currGMTDate.day());
        system.debug('recordLastModifiedDay ' + recordLastModifiedDay);
        system.debug('lastModifiedHour ' + lastModifiedHour);
        system.debug('curreStartTime.hour() ' + curreStartTime.hour());*/
        // check if current date is equal and last modified hour greater than equal start of business day
        if (currGMTDate.day() == recordLastModifiedDay && lastModifiedHour >= curreStartTime.hour()) {
            integer lastModifiedHourPlus7 = lastModifiedHour+7;
            //system.debug('lastModifiedHour+7 ' + lastModifiedHourPlus7);
            //system.debug('currSystemHour ' + currSystemHour);
            // check if current time is start time plus 7
            if (curreStartTime.hour() == lastModifiedHour) {
                //system.debug('curreStartTime.hour() == lastModifiedHour) ');
                if (lastModifiedHourPlus7 == currSystemHour)
                    return true;
            }
            else {
                //system.debug('ELSE curreStartTime.hour() == lastModifiedHour) ');
                if(lastModifiedHourPlus7 == currSystemHour && lastModifiedHourPlus7<=curreEndTime.hour())
                    return true;
            }
        }
        else {
            // get the hour prior end of business day, after business hours and before start of business hour
            integer hourBeforeEOD;
            if (lastModifiedHour <= curreEndTime.hour())
            	hourBeforeEOD = curreEndTime.hour() - lastModifiedHour;
            else {
                hourBeforeEOD = 0;
            }
            //system.debug(' hourBeforeEOD ' + hourBeforeEOD);
            //system.debug(' currSystemHour ' + currSystemHour);
            integer currStartPlus7Lesshour = curreStartTime.hour() + (7 - hourBeforeEOD);
            //system.debug(' currStartPlus7Lesshour ' + currStartPlus7Lesshour);
            if(currStartPlus7Lesshour == currSystemHour && currStartPlus7Lesshour<=curreEndTime.hour())
                return true;
        }
        
        return sendAlert;
    }
    
    private Time getDayEndTime(boolean isGetStart, string countryName, datetime myDateTime, string timeZoneName) {
        BusinessHours bh = businessHoursMap.get(countryName);
        
        Datetime GMTDate = myDateTime;
        //GMTDate = DateTime.newInstance(2023, 11, 17, 16, 3, 3);
        String strConvertedDate = 
            GMTDate.format('MM/dd/yyyy HH:mm:ss', 
                           timeZoneName);
        
        Timezone tz = Timezone.getTimeZone(timeZoneName);
        Integer offset = tz.getOffset(GMTDate);
        Datetime local = GMTDate.addSeconds(offset/1000);
        
        String dayOfWeek = local.format('E'); // dayOfWeek is Sun, Mon, Tue, etc.
        Time timeToUse = null;
        
        // get business hour end time
        switch on dayOfWeek {
            when 'Mon' {
                timeToUse = (isGetStart) ? bh.MondayStartTime : bh.MondayEndTime;
            }
            when 'Tue' {
                timeToUse = (isGetStart) ? bh.TuesdayStartTime : bh.TuesdayEndTime;
            }
            when 'Wed' {
                timeToUse = (isGetStart) ? bh.WednesdayStartTime : bh.WednesdayEndTime;
            }
            when 'Thu' {
                timeToUse = (isGetStart) ? bh.ThursdayStartTime : bh.ThursdayEndTime;
            }
            when 'Fri' {
                timeToUse = (isGetStart) ? bh.FridayStartTime : bh.FridayEndTime;
            }
            when 'Sat' {
                timeToUse = (isGetStart) ? bh.SaturdayStartTime : bh.SaturdayEndTime;
            }
            when 'Sun' {
                timeToUse = (isGetStart) ? bh.SundayStartTime : bh.SundayEndTime;
            }
        }
        return timeToUse;
    }
    
    /* 
* performs the logic to calculate if current time is almost with in an hour of EOB
* */    
    /*public boolean isWithInAnHourOfEOB(string countryName, string timeZoneName) {
        Boolean isWithIn = false;
        BusinessHours bh = businessHoursMap.get(countryName);
        
        Datetime GMTDate = system.now();
        //that is 
        String strConvertedDate = 
            GMTDate.format('MM/dd/yyyy HH:mm:ss', 
                           timeZoneName);
        
        integer currHour = integer.valueOf(strConvertedDate.substring(11,13));
        Timezone tz = Timezone.getTimeZone(timeZoneName);
        Integer offset = tz.getOffset(GMTDate);
        Datetime local = GMTDate.addSeconds(offset/1000);
        
        String dayOfWeek = local.format('E'); // dayOfWeek is Sun, Mon, Tue, etc.
        Time myTime = null;
        
        // get business hour end time
        switch on dayOfWeek {
            when 'Mon' {
                myTime = bh.MondayEndTime;
            }
            when 'Tue' {
                myTime = bh.TuesdayEndTime;
            }
            when 'Wed' {
                myTime = bh.WednesdayEndTime;
            }
            when 'Thu' {
                myTime = bh.ThursdayEndTime;
            }
            when 'Fri' {
                myTime = bh.FridayEndTime;
            }
            when 'Sat' {
                myTime = bh.SaturdayEndTime;
            }
            when 'Sun' {
                myTime = bh.SundayEndTime;
            }
        }
        
        if (myTime != null)
        {
            integer diff = myTime.hour() - currHour;
            if (diff==1)
                isWithIn = true;
            
        }
        
        return isWithIn;
    }*/
    
    
}