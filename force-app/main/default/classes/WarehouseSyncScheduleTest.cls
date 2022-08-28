@isTest
public with sharing class WarehouseSyncScheduleTest {
    // implement scheduled code here
    @isTest
    static void testSchedule() {
        String cronSchedule = '0 0 0 ? * * *'; // runs at 12:00 AM Every Day
        Test.startTest();
        //System.debug('startTest');
        Test.setMock(HttpCalloutMock.class, new WarehouseCalloutServiceMock());
        String jobId = System.schedule('Warehouse Callout Schedule Every Day Testing',
                                      cronSchedule, new WarehouseSyncSchedule());
        //System.debug('stopTest');
        Test.stopTest();
        
        //System.debug('after section');
        CronTrigger cronTrigger = [select State from CronTrigger where Id = :jobId];
        System.assertEquals('WAITING', String.valueOf(cronTrigger.State), 'Not match');
    }
}