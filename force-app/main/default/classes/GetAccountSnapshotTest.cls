// FILE: force-app/main/default/classes/GetAccountSnapshotTest.cls
@isTest(SeeAllData=false)
private class GetAccountSnapshotTest {
    @TestSetup
    static void setup() {
        Account acct = new Account(
            Name = 'Acme Corporation',
            Industry = 'Technology',
            AnnualRevenue = 5000000
        );
        insert acct;

        List<Opportunity> opportunities = new List<Opportunity>{
            new Opportunity(
                Name = 'Open Opp 1',
                AccountId = acct.Id,
                StageName = 'Prospecting',
                CloseDate = Date.today().addDays(30)
            ),
            new Opportunity(
                Name = 'Open Opp 2',
                AccountId = acct.Id,
                StageName = 'Negotiation',
                CloseDate = Date.today().addDays(15)
            ),
            new Opportunity(
                Name = 'Closed Opp',
                AccountId = acct.Id,
                StageName = 'Closed Won',
                CloseDate = Date.today().addDays(-5)
            )
        };
        insert opportunities;

        List<Contact> contacts = new List<Contact>{
            new Contact(FirstName = 'Alice', LastName = 'Anderson', AccountId = acct.Id, Title = 'CEO', Email = 'alice@example.com'),
            new Contact(FirstName = 'Bob', LastName = 'Brown', AccountId = acct.Id, Title = 'CFO', Email = 'bob@example.com'),
            new Contact(FirstName = 'Carol', LastName = 'Clark', AccountId = acct.Id, Title = 'CTO', Email = 'carol@example.com')
        };
        insert contacts;

        List<Task> tasks = new List<Task>{
            new Task(Subject = 'Follow up 1', WhatId = acct.Id, Status = 'Not Started'),
            new Task(Subject = 'Follow up 2', WhatId = acct.Id, Status = 'In Progress')
        };
        insert tasks;
    }

    @isTest
    static void test_happyPath() {
        Account acct = [SELECT Id FROM Account LIMIT 1];

        GetAccountSnapshot.AccountSnapshotInput input = new GetAccountSnapshot.AccountSnapshotInput();
        input.accountId = acct.Id;

        Test.startTest();
        List<GetAccountSnapshot.AccountSnapshotOutput> outputs = GetAccountSnapshot.getSnapshot(
            new List<GetAccountSnapshot.AccountSnapshotInput>{ input }
        );
        Test.stopTest();

        System.assertEquals(1, outputs.size(), 'Expected exactly one output for one input');
        // NOTE: local variable named 'snapshotJson' — Apex is case-insensitive so naming it
        // 'json' would clash with the JSON system class and cause a compile error.
        String snapshotJson = outputs[0].snapshotJson;
        System.assert(snapshotJson.contains('Acme Corporation'), 'Expected account name in JSON: ' + snapshotJson);
        System.assert(snapshotJson.contains('Open Opp 1'), 'Expected first open opportunity in JSON: ' + snapshotJson);
        System.assert(snapshotJson.contains('Open Opp 2'), 'Expected second open opportunity in JSON: ' + snapshotJson);
        System.assert(!snapshotJson.contains('Closed Opp'), 'Closed opportunity should not appear in JSON: ' + snapshotJson);
        System.assert(snapshotJson.contains('Alice Anderson'), 'Expected contact name in JSON: ' + snapshotJson);
        // FIX: Deserialize to check openTaskCount as an integer, not as a raw string,
        // so the assertion is immune to serialiser whitespace differences.
        Map<String, Object> parsed = (Map<String, Object>) JSON.deserializeUntyped(snapshotJson);
        System.assertEquals(2, (Integer) parsed.get('openTaskCount'), 'Expected open task count of 2');
    }

    @isTest
    static void test_invalidId() {
        Id fakeAccountId = '001000000000000AAA';

        GetAccountSnapshot.AccountSnapshotInput input = new GetAccountSnapshot.AccountSnapshotInput();
        input.accountId = fakeAccountId;

        Test.startTest();
        List<GetAccountSnapshot.AccountSnapshotOutput> outputs = GetAccountSnapshot.getSnapshot(
            new List<GetAccountSnapshot.AccountSnapshotInput>{ input }
        );
        Test.stopTest();

        System.assertEquals(1, outputs.size(), 'Expected exactly one output for one input');
        System.assert(outputs[0].snapshotJson.contains('error'), 'Expected error JSON, got: ' + outputs[0].snapshotJson);
    }

    // FIX: Added test for null accountId — WHERE Id = :null returns 0 rows,
    // so the method should return the same "No account found" error JSON rather than throwing.
    @isTest
    static void test_nullAccountId() {
        GetAccountSnapshot.AccountSnapshotInput input = new GetAccountSnapshot.AccountSnapshotInput();
        input.accountId = null;

        Test.startTest();
        List<GetAccountSnapshot.AccountSnapshotOutput> outputs = GetAccountSnapshot.getSnapshot(
            new List<GetAccountSnapshot.AccountSnapshotInput>{ input }
        );
        Test.stopTest();

        System.assertEquals(1, outputs.size(), 'Expected exactly one output for a null input');
        String json = outputs[0].snapshotJson;
        System.assert(json != null, 'Output JSON must not be null for a null accountId');
        System.assert(json.contains('error'), 'Expected an error JSON for a null accountId, got: ' + json);
    }
}
