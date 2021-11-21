@isTest
public class AccountTriggerTest {
    @testsetup static void createTestData(){
        List<Account> accs = new List<Account>();
        Account acc = new Account();
        acc.Name = 'John Harper';
        accs.add(acc);
        
        Account acc1 = new Account();
        acc1.Name = 'John Harper Test Dummy';
        acc1.email__c = 'himanshu.sfdc.84@gmail.com';
        accs.add(acc1);        
        
        insert accs;
    }
    
    // method to verify, email is mandatory, if account name contains any invalid text
    @isTest
    public static void mandatoryEmail(){
        List<Account> acclist = [SELECT id, Name, Email__c FROM Account where Name = 'John Harper' Limit 1];
        IF(accList.size() == 0){
            return;
        }
        Account acc = acclist[0];
        acc.Name = 'incorrect Test Dummy';
        try{
            Test.startTest();
            update acc;
            Test.stopTest();
        }catch(Exception ex){
            system.assert(ex.getMessage().contains('Email cannot be empty, Please populate Email'));    
        }
    }
    
    // send email, if account name contains invalid text
    @isTest
    public static void invalidText(){
        Account acc = new Account();
        acc.Name = 'incorrect Test Dummy';
        acc.email__c = 'himanshu.log.84@gmail.com';
        try{
            Test.startTest();
            insert acc;
            Test.stopTest();
        }catch(Exception ex){
            system.debug(ex);
        }
        system.assert(acc.Id != null);
    }    
    
    // do not send email, if account name changed and it contains invalid text
    @isTest
    public static void nameNotChanged(){
        List<Account> acclist = [SELECT id, Name, Email__c FROM Account where Name = 'John Harper Test Dummy' Limit 1];
        IF(accList.size() == 0){
            return;
        }
        Account acc = acclist[0];
        acc.Email__c = 'himanshu.log.84@gmail.com';
        try{
            Test.startTest();
            update acc;
            Test.stopTest();
        }catch(Exception ex){
            system.debug(ex);
        }
        system.assert(acc.Id != null);
    }    
}