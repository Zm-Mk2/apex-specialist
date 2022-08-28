@IsTest
private class WarehouseCalloutServiceTest {
    // implement your mock callout test here
	@isTest
    public static void testWarehouseCalloutService() {
        Test.setMock(HttpCalloutMock.class, new WarehouseCalloutServiceMock());
        Test.startTest();
        Id jobId = System.enqueueJob(new WarehouseCalloutService());
        Test.stopTest();
        
        List<Product2> equipments = [select Warehouse_SKU__c from Product2];
        
        System.debug(equipments);
        
        System.assertNotEquals(null, jobId);
        System.assertEquals(3, equipments.size());
        System.assertEquals('100003', equipments.get(0).Warehouse_SKU__c);
    }
}