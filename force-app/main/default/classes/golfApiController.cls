global without sharing class golfApiController {
    private string apikey{get;set;}
    private string apihost{get;set;}
    public List<Contact> contactsToUpsert{get;set;}
    public golfApiController() {
        Golf_API__c golf = Golf_API__c.getInstance();
        apikey = golf.API_Key__c;
        apihost = golf.API_Host__C;
        contactsToUpsert = new List<Contact>();
        System.debug(apikey);
        System.debug(apihost);

    }

    @AuraEnabled
    public static List<Contact> getGolfers(){
        Id golfRecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Golf').getRecordTypeId();
        List<Contact> golfers = new List<Contact>();
        golfers = [SELECT id, firstName, lastName, golf_player_id__c, golf_movement__c, golf_position__c FROM Contact WHERE recordTypeId = :golfRecordTypeId ORDER BY golf_position__c ASC];
        return golfers;
    }

    public void getWorldRankings() {
        Id golfRecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Golf').getRecordTypeId();
        string worldRankingUrl = 'https://golf-leaderboard-data.p.rapidapi.com/world-rankings';
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        req.setEndpoint(worldRankingUrl);
        req.setMethod('GET');
        req.setHeader('X-RapidAPI-Key', apikey);
        req.setHeader('X-RapidAPI-Host', apihost);
        HttpResponse res = h.send(req);
        String json = res.getBody();
        // Map<String, Object> ResponseMap = (Map<String,Object>) JSON.deserializeUntyped(json);
        // Map<String,Object> dataMap = (Map<String,Object>)responseMap.get('data');
        // String accountNumber = (String)dataMap.get('account_number');
        rankingsResponse rankres = deserialize(res);
        List<rankingsClass> players = new List<rankingsClass>();
        players = rankres.results.rankings;
        contactsToUpsert = upsertPlayers(players, golfRecordTypeId);
        upsert contactsToUpsert golf_player_id__c;
    }

    public List<Contact> upsertPlayers(List<rankingsClass> rankings, id golfrecordtype) {
        List<Contact> returnlist = new List<Contact>();

        for(rankingsClass r : rankings) {
            List<String> namelist = r.player_name.split(' ');
            Contact con = new Contact();
            con.recordTypeId = golfrecordtype;
            con.firstName = namelist[0].trim();
            con.lastName = namelist[1].trim();
            // if(namelist.size() == 2) {
            //     con.lastName = namelist[1].trim();
            // } else {
            //     for(integer i = 1; i < namelist.size(); i++) {
            //         con.lastName += namelist[i].trim();
            //     }
            // }
            
            con.golf_player_id__c = r.player_id;
            con.golf_position__c = r.position;
            con.golf_movement__c = r.movement;
            con.golf_avg_points__c = r.avg_points;
            con.golf_number_of_events__c = r.num_events;
            con.golf_points_gained__c = r.points_gained;
            con.golf_points_lost__c = r.points_lost;
            con.golf_total_points__c = r.total_points;
            returnlist.add(con);
        }
        return returnlist;
    }

    public static rankingsResponse deserialize(httpResponse res) {
        return (rankingsResponse)JSON.deserialize(res.getBody(), rankingsResponse.class);
    }

    public class rankingsResponse {
        public metaClass meta {get;set;}
        public resultsClass results {get;set;}
    }

    public class metaClass {
        public string title {get;set;}
        public string description {get;set;}
        public fieldsClass fields {get;set;}
    }

    public class fieldsClass {
        public string last_updated {get;set;}
    }

    public class resultsClass {
        public string last_updated {get;set;}
        public List<rankingsClass> rankings {get;set;}
    }

    public class rankingsClass {
        public integer position {get;set;} 
        public integer movement {get;set;} 
        public integer player_id {get;set;} 
        public string player_name {get;set;} 
        public integer num_events {get;set;} 
        public decimal avg_points {get;set;}  
        public decimal total_points {get;set;}  
        public decimal points_lost {get;set;} 
        public decimal points_gained {get;set;}
    }
}