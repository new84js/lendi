// trigger to handle all account operations
trigger AccountTrigger on Account (before insert, before update, after insert, after update, before delete, after delete, after undelete) {

    // check if trigger should fire
    IF(!Common.checkTriggerIsEnabled('AccountTrigger')){
        system.debug('AccountTrigger will not fire');
        return;
    }
    AccountTriggerHandler handler = new AccountTriggerHandler();
    
    system.debug('AccountTrigger will fire');
    IF((trigger.isInsert || trigger.isUpdate) && trigger.isBefore){
        handler.validateAccountName(Trigger.New, Trigger.oldMap); // method is bulkified
    }
    IF((trigger.isInsert || trigger.isUpdate) && trigger.isAfter){
        handler.sendEmailForInvalidAccount(Trigger.New, Trigger.oldMap); // method is bulkified
    }    
}