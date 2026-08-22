// FILE: force-app/main/default/classes/SearchContentLibrary.cls
public with sharing class SearchContentLibrary {
    public class ContentSearchInput {
        @InvocableVariable(label='Search Query' description='Keywords to search' required=true)
        public String queryText;

        @InvocableVariable(label='Max Results' description='Maximum records to return (default 3)' required=false)
        public Integer maxResults;
    }

    public class ContentSearchOutput {
        @InvocableVariable(label='Results JSON' description='JSON array of {id, title, description, fileType}')
        public String resultsJson;
    }

    @InvocableMethod(label='Search Content Library' description='Full-text searches ContentDocument Title and Description. Returns top matches as a JSON array.')
    public static List<ContentSearchOutput> search(List<ContentSearchInput> inputs) {
        List<ContentSearchOutput> outputs = new List<ContentSearchOutput>();

        for (ContentSearchInput input : inputs) {
            ContentSearchOutput output = new ContentSearchOutput();
            try {
                Integer resultLimit = input.maxResults != null ? input.maxResults : 3;
                String searchTerm = input.queryText;

                List<List<SObject>> searchResults = [
                    FIND :searchTerm IN ALL FIELDS
                    RETURNING ContentDocument(Id, Title, Description, FileType LIMIT :resultLimit)
                ];

                List<Map<String, Object>> results = new List<Map<String, Object>>();
                if (!searchResults.isEmpty()) {
                    for (SObject sobj : searchResults[0]) {
                        ContentDocument doc = (ContentDocument) sobj;
                        results.add(new Map<String, Object>{
                            'id' => doc.Id,
                            'title' => doc.Title,
                            'description' => doc.Description,
                            'fileType' => doc.FileType
                        });
                    }
                }

                output.resultsJson = JSON.serialize(results);
            } catch (Exception e) {
                output.resultsJson = JSON.serialize(new Map<String, String>{ 'error' => e.getMessage() });
            }
            outputs.add(output);
        }

        return outputs;
    }
}
