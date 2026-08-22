// FILE: force-app/main/default/classes/LogAgentInteractionTest.cls
@isTest(SeeAllData=false)
private class LogAgentInteractionTest {
    @isTest
    static void test_happyPath() {
        LogAgentInteraction.LogInput input = new LogAgentInteraction.LogInput();
        input.topicName = 'Account Insights';
        input.userQuery = 'What is the status of Acme Corporation?';
        input.outcome = 'success';
        input.citedRecordIds = '001000000000001,006000000000001';

        Test.startTest();
        List<LogAgentInteraction.LogOutput> outputs = LogAgentInteraction.logInteraction(
            new List<LogAgentInteraction.LogInput>{ input }
        );
        Test.stopTest();

        System.assertEquals(1, outputs.size(), 'Expected exactly one output for one input');
        System.assertNotEquals(null, outputs[0].logId, 'Expected a non-null Id after successful insert');

        AccountScoutLog__c logRecord = [
            SELECT TopicName__c, UserQuery__c, Outcome__c, CitedRecordIds__c
            FROM AccountScoutLog__c
            WHERE Id = :outputs[0].logId
        ];
        System.assertEquals('Account Insights', logRecord.TopicName__c);
        System.assertEquals('What is the status of Acme Corporation?', logRecord.UserQuery__c);
        System.assertEquals('success', logRecord.Outcome__c);
        System.assertEquals('001000000000001,006000000000001', logRecord.CitedRecordIds__c);
    }

    @isTest
    static void test_dmlFailureReturnsNullId() {
        LogAgentInteraction.LogInput input = new LogAgentInteraction.LogInput();
        input.topicName = 'Account Insights';
        input.userQuery = 'What is the status of Acme Corporation?';
        input.outcome = 'not_a_valid_outcome';
        input.citedRecordIds = '';

        Test.startTest();
        List<LogAgentInteraction.LogOutput> outputs = LogAgentInteraction.logInteraction(
            new List<LogAgentInteraction.LogInput>{ input }
        );
        Test.stopTest();

        System.assertEquals(1, outputs.size(), 'Expected exactly one output for one input');
        System.assertEquals(null, outputs[0].logId, 'Expected a null Id when the insert fails, not an exception');
    }

    @isTest
    static void test_bulkInsert() {
        List<LogAgentInteraction.LogInput> inputs = new List<LogAgentInteraction.LogInput>();
        for (Integer i = 0; i < 10; i++) {
            LogAgentInteraction.LogInput input = new LogAgentInteraction.LogInput();
            input.topicName = 'Topic ' + i;
            input.userQuery = 'Query ' + i;
            input.outcome = 'success';
            input.citedRecordIds = '';
            inputs.add(input);
        }

        Test.startTest();
        List<LogAgentInteraction.LogOutput> outputs = LogAgentInteraction.logInteraction(inputs);
        Test.stopTest();

        System.assertEquals(10, outputs.size(), 'Expected one output per input');
        Integer insertedCount = [SELECT COUNT() FROM AccountScoutLog__c];
        System.assertEquals(10, insertedCount, 'Expected all 10 records to be inserted in a single bulk call');
    }
}
