trigger MaintenanceRequest on Case (before update, after update) {
    // ToDo: Call MaintenanceRequestHelper.updateWorkOrders
    if (Trigger.isAfter && Trigger.isUpdate) {
        MaintenanceRequestHelper.updateWorkOrders(Trigger.new);

    }
}
/*
trigger MaintenanceRequest on Case (before update, after update) {
    // ToDo: Call MaintenanceRequestHelper.updateWorkOrders
    Map<Id, Case> validCaseMap = new Map<Id, Case>();
    
    if (Trigger.isAfter && Trigger.isUpdate) {
        for (Case caseHere : Trigger.New) {
            if (caseHere.isClosed) {
                if (caseHere.Type.equals('Repair') || caseHere.Type.equals('Routine Maintenance')) {
                    validCaseMap.put(caseHere.Id, caseHere);
                }
            }
        }
        if (!validCaseMap.values().isEmpty()) {
            MaintenanceRequestHelper.createNewRequest(validCaseMap);
        }
    }
}
*/