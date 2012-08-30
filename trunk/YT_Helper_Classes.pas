unit YT_Helper_Classes;

interface

uses System.Classes, FMX.Types;

//--> Video categories
type TYT_VideoCategory = record
  Category_LanguageID: String;
  Category_Label: String;
  Category_Term: String;
  Category_Regions: String;
  Assignable: Boolean;
end;
//<-- Video categories

//--> Channel categories
type TYT_ChannelCategory = record
  CategoryLabel: String;
  CategoryTerm: String;
end;
//<-- Channel categories

//--> User profile
type TYT_UserProfile = record
    Channel_Created_Date: TDateTime;
    Channel_Modified_Date: TDateTime;
    Channel_Category: String;
    Channel_Title: String;
    Channel_Description: String;
    Channel_AlternativeChannelLink: String;
    Channel_InsightLink: String;
    Channel_InfoLink: String;
    Channel_EditLink: String;
    Channel_Author_Name: String;
    Channel_Author_UserID: String;
    Channel_MaxUploadDuration: Integer;
    Channel_AvatarLink: String;
    Channel_AvatarBitmap: TBitmap;
    Channel_YTUserID: String;
    Channel_YTUsername: String;

    User_YT_Username: String;
    User_FirstName: String;
    User_LastName: String;
    User_About: String;
    User_Age: String;
    User_Books: String;
    User_Gender: String;
    User_Company: String;
    User_Hobbies: String;
    User_Hometown: String;
    User_Location: String;
    User_Movies: String;
    User_Music: String;
    User_Relationship: String;
    User_Occupation: String;
    User_School: String;

    Links_WatchHistory: String;
    Links_LiveEvents: String;
    Links_LiveEvents_Count: Double;
    Links_Favorites: String;
    Links_Favorites_Count: Double;
    Links_Contacts: String;
    Links_Contacts_Count: Double;
    Links_Inbox: String;
    Links_Inbox_Count: Double;
    Links_Playlists: String;
    Links_WatchLater: String;
    Links_WatchLater_Count: Double;
    Links_Subscriptions: String;
    Links_Subscriptions_Count: Double;
    Links_Uploads: String;
    Links_Uploads_Count: Double;
    Links_NewSubscriptionVideos: String;
    Links_RecentActivity: String;

    Statistics_LastAccess: TDateTime;
    Statistics_ChannelViews: Double;
    Statistics_WatchedVideos: Double;
    Statistics_Subscribers: Double;
    Statistics_Favorites: Double;
    Statistics_VideoViews: Double;
    Statistics_Uploads: Double;
    Statistics_Subscriptions: Double;
    Statistics_Contacts: Double;
    Statistics_Inbox: Double;
    Statistics_WatchLater: Double;
  end;
//<-- User profile

//--> Main classes
type
  TYT_VideoCategories = Array of TYT_VideoCategory;
  TYT_ChannelCategories = Array of TYT_ChannelCategory;
  TYT_UserInfo = TYT_UserProfile;
//<-- Main classes

implementation

end.
