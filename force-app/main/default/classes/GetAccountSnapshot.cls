// FILE: force-app/main/default/classes/GetAccountSnapshot.cls
public without sharing class GetAccountSnapshot {
    public class AccountSnapshotInput {
        @InvocableVariable(label='Account ID' description='18-character Salesforce Account ID' required=true)
        public Id accountId;
    }

    public class AccountSnapshotOutput {
        @InvocableVariable(label='Snapshot JSON' description='The full result as a serialized JSON string')
        public String snapshotJson;
    }

    @InvocableMethod(label='Get Account Snapshot' description='Returns account details, open opportunities, top contacts, and open task count as a JSON string.')
    public static List<AccountSnapshotOutput> getSnapshot(List<AccountSnapshotInput> inputs) {
        List<AccountSnapshotOutput> outputs = new List<AccountSnapshotOutput>();

        for (AccountSnapshotInput input : inputs) {
            AccountSnapshotOutput output = new AccountSnapshotOutput();
            try {
                Id accountId = input.accountId;

                List<Account> accounts = [
                    SELECT Id, Name, Industry, AnnualRevenue, Owner.Name
                    FROM Account
                    WHERE Id = :accountId
                    WITH SECURITY_ENFORCED
                    LIMIT 1
                ];

                if (accounts.isEmpty()) {
                    output.snapshotJson = JSON.serialize(
                        new Map<String, String>{ 'error' => 'No account found for the given Account ID.' }
                    );
                    outputs.add(output);
                    continue;
                }

                Account acct = accounts[0];

                List<Opportunity> opportunities = [
                    SELECT Id, Name, StageName, Amount, CloseDate
                    FROM Opportunity
                    WHERE AccountId = :accountId AND IsClosed = false
                    WITH SECURITY_ENFORCED
                    ORDER BY CloseDate ASC
                    LIMIT 5
                ];

                List<Contact> contacts = [
                    SELECT Id, Name, Title, Email
                    FROM Contact
                    WHERE AccountId = :accountId
                    WITH SECURITY_ENFORCED
                    ORDER BY CreatedDate DESC
                    LIMIT 3
                ];

                Integer openTaskCount = [
                    SELECT COUNT()
                    FROM Task
                    WHERE WhatId = :accountId AND Status != 'Completed'
                    WITH SECURITY_ENFORCED
                ];

                Map<String, Object> accountMap = new Map<String, Object>{
                    'Id' => acct.Id,
                    'Name' => acct.Name,
                    'Industry' => acct.Industry,
                    'AnnualRevenue' => acct.AnnualRevenue,
                    'OwnerName' => acct.Owner != null ? acct.Owner.Name : null
                };

                List<Map<String, Object>> opportunityList = new List<Map<String, Object>>();
                for (Opportunity opp : opportunities) {
                    opportunityList.add(new Map<String, Object>{
                        'Id' => opp.Id,
                        'Name' => opp.Name,
                        'StageName' => opp.StageName,
                        'Amount' => opp.Amount,
                        'CloseDate' => opp.CloseDate
                    });
                }

                List<Map<String, Object>> contactList = new List<Map<String, Object>>();
                for (Contact con : contacts) {
                    contactList.add(new Map<String, Object>{
                        'Id' => con.Id,
                        'Name' => con.Name,
                        'Title' => con.Title,
                        'Email' => con.Email
                    });
                }

                Map<String, Object> result = new Map<String, Object>{
                    'account' => accountMap,
                    'opportunities' => opportunityList,
                    'contacts' => contactList,
                    'openTaskCount' => openTaskCount
                };

                output.snapshotJson = JSON.serialize(result);
            } catch (Exception e) {
                output.snapshotJson = JSON.serialize(new Map<String, String>{ 'error' => e.getMessage() });
            }
            outputs.add(output);
        }

        return outputs;
    }
}
