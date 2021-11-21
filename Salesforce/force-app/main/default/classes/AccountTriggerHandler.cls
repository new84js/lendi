public class AccountTriggerHandler {

    //method will be called in before insert and update on Account
    // purpose: if account name has any invalid text, then email__c is mandatory to be filled (since we will need to send email)
    // list of invalid texts are defined in custom metadata (CommonConfig__mdt, key - 'AccountNameInvalidText')
    public void validateAccountName(List<Account> newRecords, Map<ID, Account> oldRecords){
        system.debug('executing validateAccountName');
        FOR(Account accRec: newRecords){
            try{
                // If account name not changed, skip to next record
                IF(oldRecords != null &&
                   accRec.Id != null &&
                   accRec.Name == oldRecords.get(accRec.Id).Name){
                       continue;
                   }
                
                // below code will only execute on: a)insert b) update record and account.name is changed 
                system.debug('checking for name');
                IF(Common.invalidTextInAccountName(accRec) != null){
                    IF(Common.accountEmailEmpty(accRec)){
                        // email__c field is mandatory, when name contains invalid text, since we will need this email id, to send email
                        accRec.addError('Email cannot be empty, Please populate Email');
                    }
                }
            } catch(Exception ex){
                accRec.addError('Exception Received: '+ ex);
            }
        }// end of FOR loop
        system.debug('exiting validateAccountName');
    }
    
    // this method will be called in after update and insert on account
    // purpose: if name contains invalid text, send an email on Account.email__c field
    public void sendEmailForInvalidAccount(List<Account> newRecords, Map<Id, Account> oldRecords){
        system.debug('executing sendEmailForInvalidAccount');
        Map<ID, String> invalidAccNameMap = new Map<ID, String>(); 
        FOR(Account accRec: newRecords){
            IF(accRec == null || accRec.Name == null || accRec.Name == ''){
                continue;
            }
            try{
                IF(oldRecords != null &&
                   accRec.Id != null &&
                   accRec.Name == oldRecords.get(accRec.Id).Name){
                       continue;
                   }
                
                // below code will only execute on: a)insert b) update, if name is changed             
                system.debug('checking for name');
                String invalidText = Common.invalidTextInAccountName(accRec);
                IF(invalidText != null){
                    IF(!Common.accountEmailEmpty(accRec)){
                        system.debug(accRec.Id);
                        invalidAccNameMap.put(accRec.Id, invalidText);
                    }
                }
            }catch(Exception ex){
                system.debug('Exception received:'+ex);
            }
        }// end of FOR loop
        IF(invalidAccNameMap.size() > 0){
            Common.prepareToSendEmail(invalidAccNameMap);// send map, so we do not call future method multiple times.
        }
        system.debug('exiting sendEmailForInvalidAccount');
    }        
}