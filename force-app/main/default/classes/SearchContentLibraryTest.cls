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
        System.assertNotEquals(null, outputs[0].resultsJson, 'Expected a non-null JSON result');
        Object parsed = JSON.deserializeUntyped(outputs[0].resultsJson);
        System.assert(parsed instanceof List<Object>, 'Expected resultsJson to be a JSON array: ' + outputs[0].resultsJson);
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

    @isTest
    static void test_buildResultMaps_includesTitle() {
        ContentDocument doc = (ContentDocument) JSON.deserialize(
            '{"attributes":{"type":"ContentDocument"},"Title":"Healthcare Evaluation Guide","Description":"healthcare evaluation","FileType":"PDF"}',
            ContentDocument.class
        );

        Test.startTest();
        List<Map<String, Object>> results = SearchContentLibrary.buildResultMaps(new List<ContentDocument>{ doc });
        Test.stopTest();

        String json = JSON.serialize(results);
        System.assertEquals(1, results.size(), 'Expected one mapped result');
        System.assert(json.contains('Healthcare Evaluation Guide'), 'Expected title in mapped JSON: ' + json);
        System.assert(json.contains('healthcare evaluation'), 'Expected description in mapped JSON: ' + json);
        System.assert(json.contains('PDF'), 'Expected file type in mapped JSON: ' + json);
    }

    @isTest
    static void test_buildResultMaps_empty() {
        Test.startTest();
        List<Map<String, Object>> results = SearchContentLibrary.buildResultMaps(new List<ContentDocument>());
        Test.stopTest();

        System.assertEquals(0, results.size(), 'Expected no mapped results for an empty document list');
    }

    private static List<Id> getContentDocumentIds() {
        List<ContentDocument> docs = [SELECT Id FROM ContentDocument];
        return new List<Id>(new Map<Id, ContentDocument>(docs).keySet());
    }
}
