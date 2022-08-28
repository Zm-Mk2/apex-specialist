public with sharing class MaintenanceRequestHelper {
    
    public static void updateWorkOrders(List<Case> cases) {
        // TODO: Complete the method to update workorders
        // Collect the id of the Maintenance Request record to process
        Set<Id> ids = new Set<Id>();

        // Get the Maintenance Request Ids based on the Type = Repair or Routine Maintenance and Status is closed
        for (Case c : cases) {
            if ( (c.Type == 'Repair' || c.Type == 'Routine Maintenance') && c.Status == 'Closed') {
                ids.add(c.Id);
            }
        }

        // When the Maintenance Request of Type (Repair or Routine Maintenance) - (Status) is Closed
        // Create a new Maintenance Request for a future Routine Maintenance checkup
        if (!ids.isEmpty()) {
            // **__rはリレーション名であり、親レコード.子レコード.子レコード項目のように親から子項目にアクセスすることが可
            // Map<Id, Case>はsObjectの対応付：SOQLで取得した結果を自動で格納為ることが可
            // IdはId,Caseそれぞれに格納される
            Map<Id, Case> closedCaseByIds = new Map<Id, Case>([SELECT Id, Vehicle__c,
            ( SELECT Id, Equipment__c, Quantity__c, Equipment__r.Maintenance_Cycle__c FROM Equipment_Maintenance_Items__r)
            FROM Case WHERE Id IN :ids]);
            //System.debug('Map closeDCaseByIds = ' + closedCaseByIds);

            /**
             * If multiple pieces of equipment are used in the maintenance request,
             * define the due date by applying the shortest maintenance cycle to today’s date.
             * */

            // Map to hold aggregated result of Maintenance cycle
            Map<Id, Decimal> idToMinCycle = new Map<Id, Decimal>();

            // Aggregate to get the Minimum of Maintenance Cycle days
            // メンテナンスリクエストのIDと一致する作業部品をIDで集約させて最小の部品の修理周期を取得
            AggregateResult[] aggregateResults = [SELECT Maintenance_Request__c, MIN(Equipment__r.Maintenance_Cycle__c) Cycle
            FROM Equipment_Maintenance_Item__c WHERE Maintenance_Request__c IN : ids GROUP BY Maintenance_Request__c];

            // Build a Map to get the Min Maintenance Cycles with Maintenance Request Id
            for (AggregateResult ar : aggregateResults){
                idToMinCycle.put((Id) ar.get('Maintenance_Request__c') , (Decimal) ar.get('Cycle'));
            }

            /*********************** */

            // List to hold the new Case to insert
            List<Case> newCases = new List<Case>();

            // Loop through the list of cases from the Map
            for (Case aCase : closedCaseByIds.values()) {
                Case newCase = new Case();
                newCase.Type = 'Routine Maintenance';
                newCase.Status = 'New';
                newCase.Vehicle__c = aCase.Vehicle__c;
                newCase.Subject = 'Auto Routine Maintenance';
                newCase.Date_Reported__c = Date.today();
                newCase.ParentId = aCase.Id;

                // get shortest maintenance cycle to today’s date
                /*
                if (idToMinCycle.containsKey(aCase.Id)) {
                    newCase.Date_Due__c = Date.today().addDays((Integer) idToMinCycle.get(aCase.Id));
                } else {
                    newCase.Date_Due__c = Date.today().addDays(0); // if there's no min cycle then add 0
                }
                 */
                newCase.Date_Due__c = Date.today().addDays(idToMinCycle.containsKey(aCase.Id) ? (Integer) idToMinCycle.get(aCase.Id) : 0 );
                newCases.add(newCase);
            }

            // Insert auto Maintenance Request
            if (newCases.size() > 0) {
                insert newCases;
            }

            // Prep related Equipment Maintenance Item
            List<Equipment_Maintenance_Item__c> equipmentMaintenanceItems = new List<Equipment_Maintenance_Item__c>();
            for (Case nCase : newCases) {
                for (Equipment_Maintenance_Item__c item : closedCaseByIds.get(nCase.ParentId).Equipment_Maintenance_Items__r) {
                    Equipment_Maintenance_Item__c equipmentMaintenanceItem = item.clone();
                    equipmentMaintenanceItem.Maintenance_Request__c = nCase.Id;
                    equipmentMaintenanceItems.add(equipmentMaintenanceItem);
                }
            }

            // Insert auto related Equipment Maintenance Item
            if (equipmentMaintenanceItems.size() > 0) {
                insert equipmentMaintenanceItems;
            }

        }

    }        
    
}
/*
public with sharing class MaintenanceRequestHelper {
    
    public static void createNewRequest(Map<Id, Case> validCaseMap) {
        // TODO: Complete the method to update workorders
        List<Case> newCases = new List<Case>();
        List<Equipment_Maintenance_Item__c> allItems = [select Id, Maintenance_Request__c, Quantity__c, Equipment__c from Equipment_Maintenance_Item__c];
        List<Equipment_Maintenance_Item__c> newEquipmentMaintenanceItems = new List<Equipment_Maintenance_Item__c>();
        Map<Id, Integer> productMaintenanceCycleMap = new Map<Id, Integer>();
        Map<Id, Integer> equipmentMaintenanceItemCycleMap = new Map<Id, Integer>();
        
        // equipment(機器のIDごとのメンテナンス周期Mapを作成)(機器Map)
		for (Product2 productHere : [select Id, Maintenance_Cycle__c from Product2]) {
            
            if (productHere.Maintenance_Cycle__c != null) {
                productMaintenanceCycleMap.put(productHere.Id, Integer.valueOf(productHere.Maintenance_Cycle__c));               
            }
        }
        
        
        // validHereMapのMaintenance Request(メンテナンスリクエスト)と同じIDを持つ作業部品を抽出
        for (Equipment_Maintenance_Item__c equipmentMaintenanceItem : [select Id, Equipment__c, Maintenance_Request__c from Equipment_Maintenance_Item__c where Maintenance_Request__c in :validCaseMap.keySet()]) {
            
            if (equipmentMaintenanceItem.Equipment__c != null) {
                // Maintenance_Request(メンテナンスリクエスト)の内、重複しないIDと機器のメンテナス周期Mapを作成(作業部品Map)
                if(!equipmentMaintenanceItemCycleMap.containsKey(equipmentMaintenanceItem.Maintenance_Request__c)){
                    equipmentMaintenanceItemCycleMap.put(equipmentMaintenanceItem.Maintenance_Request__c, productMaintenanceCycleMap.get(equipmentMaintenanceItem.Equipment__c));   
                }
                // すでに作業部品Mapに同一キーが存在する場合、機器Mapと作業部品Mapのメンテナンス周期が小さい方を格納する(一つのメンテナンス周期は、一番短いメンテナス周期が採用されるため)
                else if(productMaintenanceCycleMap.get(equipmentMaintenanceItem.Equipment__c) < equipmentMaintenanceItemCycleMap.get(equipmentMaintenanceItem.Maintenance_Request__c)){
                    equipmentMaintenanceItemCycleMap.put(equipmentMaintenanceItem.Maintenance_Request__c, productMaintenanceCycleMap.get(equipmentMaintenanceItem.Equipment__c));  
                }             
            }
        }
        
        for(Case caseHere: validCaseMap.values()){
            Case newCase = new Case();
            newCase.Vehicle__c = caseHere.Vehicle__c;
            //newCase.Equipment__c = caseHere.Equipment__c;
            newCase.Type = 'Routine Maintenance';
            newCase.Subject = String.isBlank(caseHere.Subject) ? 'Routine Maintenance Request' : caseHere.Subject + ' New';
            newCase.Date_Reported__c = Date.today();
            newCase.Date_Due__c = equipmentMaintenanceItemCycleMap.containsKey(caseHere.Product__c) ? Date.today().addDays(equipmentMaintenanceItemCycleMap.get(caseHere.Product__c)) : Date.today().addDays(equipmentMaintenanceItemCycleMap.get(caseHere.Id));
            newCase.Status = 'New';
            System.debug('newCase.Product__c = ' + caseHere.Product__c);
            newCase.Product__c = caseHere.Product__c;
            newCase.AccountId = caseHere.AccountId;
            newCase.ContactId = caseHere.ContactId;
            newCase.AssetId = caseHere.AssetId;
            newCase.Origin = caseHere.Origin;
            newCase.Reason = caseHere.Reason;
          	
            newCases.add(newCase);
            
            for(Equipment_Maintenance_Item__c oneItem : allItems){
                if (oneItem.Maintenance_Request__c == caseHere.Id) {
	                newEquipmentMaintenanceItems.add(new Equipment_Maintenance_Item__c(
    	                Equipment__c = oneItem.Equipment__c,
        	            Maintenance_Request__c = caseHere.Id,
            	        Quantity__c = oneItem.Quantity__c));
                }
            }
            
        }
        
        if (newCases.size() > 0){
            insert newCases;
        }
        
        // 新しいメンテナンスに紐づく作業部品を編集しinsert
        for (Case newCase: NewCases) {
            for (Equipment_Maintenance_Item__c newEquipmentMainItem : newEquipmentMaintenanceItems) {
                newEquipmentMainItem.Maintenance_Request__c = newCase.Id;
        	}
        }
        insert newEquipmentMaintenanceItems;
        
    }    
}
*/