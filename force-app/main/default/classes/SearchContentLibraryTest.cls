// FILE: force-app/main/default/classes/SearchContentLibraryTest.cls
@isTest(SeeAllData=false)
private class SearchContentLibraryTest {
    @TestSetup
    static void setup() {
        ContentVersion cv = new ContentVersion(
            VersionData = Blob.valueOf('test'),
            PathOnClient = 'test.pdf',
            Title = 'Healthcare Evaluation Guide',
            Description = 'healthcare evaluation'
        );
        insert cv;
    }

    @isTest
    static void test_happyPath() {
        Test.setFixedSearchResults(getContentDocumentIds());

        SearchContentLibrary.ContentSearchInput input = new SearchContentLibrary.ContentSearchInput();
        input.queryText = 'healthcare';
        input.maxResults = 3;

        Test.startTest();
        List<SearchContentLibrary.ContentSearchOutput> outputs = SearchContentLibrary.search(
            new List<SearchContentLibrary.ContentSearchInput>{ input }
        );
        Test.stopTest();

        System.assertEquals(1, outputs.size(), 'Expected exactly one output for one input');
        System.assert(
            outputs[0].resultsJson.contains('Healthcare Evaluation Guide'),
            'Expected matching title in JSON: ' + outputs[0].resultsJson
        );
    }

    @isTest
    static void test_nullMaxResults() {
        Test.setFixedSearchResults(getContentDocumentIds());

        SearchContentLibrary.ContentSearchInput input = new SearchContentLibrary.ContentSearchInput();
        input.queryText = 'healthcare';
        input.maxResults = null;

        Test.startTest();
        List<SearchContentLibrary.ContentSearchOutput> outputs = SearchContentLibrary.search(
            new List<SearchContentLibrary.ContentSearchInput>{ input }
        );
        Test.stopTest();

        System.assertEquals(1, outputs.size(), 'Expected exactly one output for one input');
        System.assertNotEquals(null, outputs[0].resultsJson, 'Expected a non-null JSON result when maxResults is null');
    }

    private static List<Id> getContentDocumentIds() {
        List<ContentDocument> docs = [SELECT Id FROM ContentDocument];
        return new List<Id>(new Map<Id, ContentDocument>(docs).keySet());
    }
}
