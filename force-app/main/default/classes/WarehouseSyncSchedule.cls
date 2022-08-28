public with sharing class WarehouseSyncSchedule implements Schedulable {
    // implement scheduled code here
	public void execute(SchedulableContext schedulableContext) {
        // 非同期に実行するための決まり(指定したものがキューに格納される)
        // 呼び出すクラスはQueueable, Database.AllowsCalloutsのインターフェースの実装要
        System.enqueueJob(new WarehouseCalloutService());
        //WarehouseCalloutService.execute();
        //String jobId = System.schedule('testSchedule', '0 0 1 * * ?', new WarehouseSyncSchedule());
    }
}