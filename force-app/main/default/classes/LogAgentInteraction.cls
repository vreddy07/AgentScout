// FILE: force-app/main/default/classes/LogAgentInteraction.cls
public with sharing class LogAgentInteraction {
    public class LogInput {
        @InvocableVariable(label='Topic Name' required=true)
        public String topicName;

        @InvocableVariable(label='User Query' required=true)
        public String userQuery;

        @InvocableVariable(label='Outcome' description='success, refusal, or error' required=true)
        public String outcome;

        @InvocableVariable(label='Cited Record IDs' description='Comma-separated list of cited record IDs' required=true)
        public String citedRecordIds;
    }

    public class LogOutput {
        @InvocableVariable(label='Log Id')
        public Id logId;
    }

    @InvocableMethod(label='Log Agent Interaction' description='Inserts an AccountScoutLog__c record to audit agent activity.')
    public static List<LogOutput> logInteraction(List<LogInput> inputs) {
        List<AccountScoutLog__c> logsToInsert = new List<AccountScoutLog__c>();

        for (LogInput input : inputs) {
            logsToInsert.add(new AccountScoutLog__c(
                TopicName__c = input.topicName,
                UserQuery__c = input.userQuery,
                Outcome__c = input.outcome,
                CitedRecordIds__c = input.citedRecordIds
            ));
        }

        List<LogOutput> outputs = new List<LogOutput>();
        try {
            insert logsToInsert;
            for (AccountScoutLog__c logRecord : logsToInsert) {
                LogOutput output = new LogOutput();
                output.logId = logRecord.Id;
                outputs.add(output);
            }
        } catch (Exception e) {
            outputs.clear();
            for (Integer i = 0; i < inputs.size(); i++) {
                LogOutput output = new LogOutput();
                output.logId = null;
                outputs.add(output);
            }
        }

        return outputs;
    }
}
