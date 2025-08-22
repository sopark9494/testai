@RestResource(urlMapping='/Account/')
global with sharing class AccountSyncController {
    
    @HttpPost
    global static String insertAccount(String jsonInput) {
        try {
            // 1. JSON을 Account 리스트로 변환
            List<Account> accountList = (List<Account>) JSON.deserialize(jsonInput, List<Account>.class);

            if (accountList.isEmpty()) {
                return 'No Account data received.';
            }

            // 2. 기존 Account 조회 (External_Id__c 기준)
            Set<String> externalIds = new Set<String>();
            for (Account acc : accountList) {
                externalIds.add(acc.External_Id__c);
            }

            Map<String, Account> existingAccounts = new Map<String, Account>();
            for (Account acc : [SELECT Id, External_Id__c FROM Account WHERE External_Id__c IN :externalIds]) {
                existingAccounts.put(acc.External_Id__c, acc);
            }

            // 3. 새로운 Account만 삽입, 기존 데이터는 업데이트
            List<Account> accountsToInsert = new List<Account>();
            List<Account> accountsToUpdate = new List<Account>();

            for (Account acc : accountList) {
                if (existingAccounts.containsKey(acc.External_Id__c)) {
                    Account existing = existingAccounts.get(acc.External_Id__c);
                    existing.Name = acc.Name;
                    existing.Phone = acc.Phone;
                    existing.Industry = acc.Industry;
                    accountsToUpdate.add(existing);
                } else {
                    accountsToInsert.add(acc);
                }
            }

            if (!accountsToInsert.isEmpty()) {
                insert accountsToInsert;
            }
            if (!accountsToUpdate.isEmpty()) {
                update accountsToUpdate;
            }

            return 'Inserted: ' + accountsToInsert.size() + ', Updated: ' + accountsToUpdate.size();

        } catch (Exception e) {
            System.debug('insertAccount Error: ' + e.getMessage());
            return 'Error: ' + e.getMessage();
        }
    }
}