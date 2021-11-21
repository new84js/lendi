public class Common {
//We will specify all common methods and constants in this class, so these methods and constants can be reused

    // this method will check, if org is a sandbox ?
    public static Boolean isSandBox(){
        Organization org = [SELECT Id, InstanceName, IsSandbox, Name, OrganizationType FROM Organization];
        system.debug(org.IsSandBox);
        return org.IsSandBox;
    }
    
    // this method, can be reused and will check, if trigger should fire for an object
    public static Boolean checkTriggerIsEnabled(String triggerCheckKey){
        IF(triggerCheckKey == null){
            return false;
        }
        triggerCheckKey += (isSandBox() ? '_Prod': '_UAT');
        IF(controlTrigger__mdt.getInstance(triggerCheckKey) != null && 
           controlTrigger__mdt.getInstance(triggerCheckKey).trigger_is_activated__c){
               return true;
           }
        return false;
    }
    
    public static String getCommonConfigValue(String configKey, Boolean diffForProdUAT){
        IF(configKey == null || diffForProdUAT == null){
            return null;
        }
        IF(diffForProdUAT){
            configKey +=(isSandBox() ? '_Prod': '_UAT');
        }
        system.debug('configKey:'+configKey);
        IF(CommonConfig__mdt.getInstance(configKey) != null &&
           CommonConfig__mdt.getInstance(configKey).Value__c != null){
               return CommonConfig__mdt.getInstance(configKey).Value__c;
           }
        return null;
    }

    //purpose: check, if account name contains any invalid text (mentioned in custom metadata-CommonConfig__mdt('AccountNameInvalidText')) 
    //Return: returns null or (comma separated) invalid texts contained in accont.Name
    public static String invalidTextInAccountName(Account acc){
        // check, if any config is specified for invalid name check
        IF(acc== null && acc.Name == null){
            return null;
        }
        List<String> checkTextList = new List<String>();
        String tmpstr;
        tmpstr = getCommonConfigValue('AccountNameInvalidText', True);
        checkTextList = (tmpstr != null ? tmpstr.split(';') : null);
        system.debug('checkTextList-'+checkTextList);
        tmpstr = null; // initializing it to reuse this tmp variable
        IF(checkTextList == null){
            system.debug('returning-'+tmpstr);
            return null;
        }
        FOR(String checkText : checkTextList){
            checkText = checkText.toLowerCase();
            String accNameLowerCase = acc.Name.toLowerCase();
            system.debug('Checking-'+checkText+', in '+accNameLowerCase);
            // verify if account name is invalid
            IF(accNameLowerCase.Contains(checkText)){
                tmpstr = (tmpstr == null ? checkText :tmpstr+ ', '+ checkText);
            }
        }
        system.debug('returning-'+tmpstr);
        return tmpstr;
    }

    //purpose: check, account.Email__c field is not empty
    //since, we will rewrite this code mutliple times, better to make a mathod is use it
    public static Boolean accountEmailEmpty(Account acc){
        IF(acc != null && (acc.email__c == null || acc.email__c == '')){
            return true;
        }
        return false;
    }    

    @future(callout=true)
    //input: map of account Id and invalid text in account name, so we do not have to identify what is invalid text in account.name field
    //purpose: we will prepare request for each entry received in Map, and make a callout to send email
    public static void prepareToSendEmail(Map<ID, String> accIdMap){
        system.debug('starting prepareToSendEmail');
        IF(accIdMap.size() == 0){
            return; // do not continue, if map is empty
        }
        FOR(Account accRec: [SELECT Id, Name, Email__c FROM Account WHERE ID in :accIdMap.keySet()]){
            try{
                system.debug(accRec);
                String invalidText = accIdMap.get(accRec.Id);
                String accName = accRec.Name;
                system.debug('Account Name: '+accName);
                system.debug('Invalid Text in Account Name: '+invalidText);
                IF(invalidText == null || invalidText == '' || accName== null || accName== ''){
                    continue; // if any of these is null or blanks, skip to next record
                }
                //preparing the request param, we may have spaces and special characters, so we will encode the text for URI compatability
                String subject = EncodingUtil.urlEncode('Your attention needed ( '+accName+' )', 'utf-8');
                String emailBody = 'Hello '+accName+',';
                emailBody +='\n\nWe have noticed your Name ('+accName+') contains ('+invalidText+'). If this needs to be corrected, Please call (1800 111 366) and get your name corrected. \n\n Please ignore this email, if No correction needed in Name. \n\n\n Thanks, \n xyz Company';
                emailBody = EncodingUtil.urlEncode(emailBody, 'utf-8');
                String emailReq = 'from=himanshu.log.84@gmail.com&to='+accRec.Email__c+'&subject='+subject+'&text='+emailBody;
                emailSend(emailReq);// method to make a callout and send email
            }catch(Exception ex){
                system.debug('Exception receievd-'+ex);
            }
        }
    }
    
    //input: request parameter, to be amended in url
    //purpose: method will make callout to send email via mailgun, it will use named credential(mailgun) to get url and login details
    private static void emailSend(String reqParam){
        IF(reqParam == null || reqParam == ''){
            return;
        }
        system.debug('reqParams='+reqParam);
        HttpRequest req = new HttpRequest();
        req.setMethod('POST');
        // refer to named credential: "mailgun"
        req.setEndpoint('callout:mailgun'+'?'+reqParam);
        Http http = new Http();
        HttpResponse response = new HttpResponse();
        IF(test.isRunningTest()){
            // handle test scenario here
            response.setStatusCode(200);
        }else{
            response = http.send(req);    
        }
        IF(response.getStatusCode()==200){
            system.debug('Email sent successfully');
        }else{
            system.debug('Error in sending email: Error Code-'+response.getStatusCode()+', '+response.getBody());
        }
    }    
}