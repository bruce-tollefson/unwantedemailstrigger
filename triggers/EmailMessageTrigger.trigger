trigger EmailMessageTrigger on EmailMessage (before insert) {
    
    List<String> acceptableEmailsList = new List<String>();
    for(Email_to_Case_Email_Account__mdt emailAct :[Select Label from Email_to_Case_Email_Account__mdt]){
        acceptableEmailsList.add(emailAct.Label);
    }
    Pattern p = Pattern.compile(String.join(acceptableEmailsList, '|'));// the | in regex acts as an OR
    
    Set<Id> caseIdSet = new Set<Id>();
    for(EmailMessage em :Trigger.New){
        if(!em.Incoming) continue;//this shouldn't fire on emails being sent out
        Boolean match = p.matcher(em.Headers).find();//you have to look at the header as the toAddress will be the routing address, to test send an email directly to the service address
        
        if(!match){
           // em.addError('Email must be sent to: '+em.ToAddress);//addError will stop the transaction and rollback but will also send and email to the email address
            caseIdSet.add(em.ParentId);//alternative this would create an audit 
        }
    }
    //Get list of bad cases and update the type value
    List<Case> auditCases = [Select Id, Type from Case where Id IN :caseIdSet];
    for(Case auditCase :auditCases){
        auditCase.Type = '***INVESTIGATE***';
    }
    
    update auditCases;
}
