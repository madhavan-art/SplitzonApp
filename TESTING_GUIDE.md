# Testing Guide: Offline-First Group Sync

## Overview
This guide explains how to test the offline-first architecture where groups are created locally in SQLite and synced to your MERN backend.

## Architecture Summary
1. **Local Storage**: Groups stored in SQLite with `syncStatus: PENDING`
2. **Backend Sync**: Groups synced to MongoDB via your MERN API
3. **Offline Support**: App works without internet, syncs when available

## Testing Scenarios

### 1. Basic Group Creation (Offline)
**What to test**: Creating groups without internet connection
**Steps**:
1. Turn off WiFi/mobile data
2. Open app and go to Home screen
3. Tap "+" floating button to create new group
4. Fill in all fields (name, description, type, budget, members, etc.)
5. Tap "Create Group"
6. Verify group appears in Home screen list
7. Check that group is saved locally (SQLite)

**Expected Result**: Group should be created and visible even without internet

### 2. Backend Sync (Online)
**What to test**: Syncing local groups to backend when internet is available
**Steps**:
1. Ensure internet connection is active
2. Make sure your MERN backend is running at: `https://nonsterile-smudgeless-candace.ngrok-free.dev`
3. Create a new group (or use existing PENDING groups)
4. The app should automatically sync PENDING groups to backend
5. Check backend logs or database to verify group was created in MongoDB

**Expected Result**: Groups with `syncStatus: PENDING` should become `SYNCED` and appear in MongoDB

### 3. Internet Connection Handling
**What to test**: How app handles internet connectivity changes
**Steps**:
1. Create groups while offline
2. Turn on internet
3. App should automatically sync PENDING groups
4. Turn off internet again
5. Create more groups (should work offline)
6. Turn on internet again
7. Verify new groups sync

**Expected Result**: App should seamlessly handle connectivity changes

### 4. Image Upload Sync
**What to test**: Banner image upload to Cloudinary
**Steps**:
1. Create group with banner image
2. Ensure internet is available
3. Verify image is uploaded to Cloudinary
4. Check that `bannerImageUrl` is populated in both SQLite and MongoDB

**Expected Result**: Banner images should be uploaded to Cloudinary and URLs stored in both databases

### 5. Fetch Groups from Backend
**What to test**: Loading existing groups from backend
**Steps**:
1. Ensure backend has existing groups in MongoDB
2. Open app with internet connection
3. App should fetch groups from backend and sync to local SQLite
4. Verify groups appear in Home screen

**Expected Result**: Groups from backend should appear in local app

## Manual Testing Commands

### Check SQLite Database
```bash
# Navigate to app directory
cd SplitzonApp

# Run app in debug mode
flutter run

# In app, create groups and check logs for:
# "✅ Group synced: [group-id]"
# "✅ Fetched [count] groups from backend"
```

### Check Backend API
```bash
# Test group creation endpoint
curl -X POST "https://nonsterile-smudgeless-candace.ngrok-free.dev/api/groups/create" \
  -H "Authorization: Bearer [your-jwt-token]" \
  -F "groupName=Test Group" \
  -F "groupDescription=Test description" \
  -F "groupType=Trip" \
  -F "currency=INR" \
  -F "overallBudget=10000" \
  -F "myShare=2500" \
  -F "members=[\"user1\",\"user2\"]"

# Test fetch groups endpoint
curl -X GET "https://nonsterile-smudgeless-candace.ngrok-free.dev/api/groups/my-groups" \
  -H "Authorization: Bearer [your-jwt-token]"
```

## Code Integration Points

### Sync Service Usage
```dart
// In your main app or after login
final syncService = SyncService();

// Sync pending groups to backend
await syncService.syncPendingGroups(authToken);

// Fetch groups from backend and sync local
await syncService.fetchAndSyncGroups(authToken);

// Delete group from backend
await syncService.deleteGroupFromBackend(groupId, authToken);
```

### Group Provider Usage
```dart
// Create group (saves to SQLite)
await context.read<GroupProvider>().createGroup(
  name: "Goa Trip",
  description: "Annual vacation",
  groupType: "Trip",
  currency: "INR",
  overallBudget: 50000,
  myShare: 12500,
  members: ["user1", "user2", "user3"],
  bannerImagePath: "/path/to/image.jpg",
);
```

## Error Handling

### Common Issues & Solutions

1. **Sync fails due to network**
   - Groups remain as PENDING in SQLite
   - App will retry sync when internet is available

2. **Backend API down**
   - Groups remain as PENDING
   - App continues to work offline
   - User gets error notification

3. **Authentication errors**
   - Check JWT token validity
   - Ensure `Authorization: Bearer [token]` header format

4. **Image upload fails**
   - BannerImagePath remains local
   - BannerImageUrl stays null
   - Group still syncs without image

## Monitoring Sync Status

### Check Sync Status in Code
```dart
final groups = await GroupProvider().groups;
for (final group in groups) {
  print('Group: ${group.name}, Status: ${group.syncStatus}');
  // PENDING = not synced yet
  // SYNCED = successfully synced to backend
}
```

### Debug Logs
Look for these log messages:
- `"✅ Group synced: [id]"` - Successful sync
- `"❌ Sync error: [error]"` - Sync failed
- `"✅ Fetched [count] groups from backend"` - Successful fetch
- `"❌ Fetch error: [error]"` - Fetch failed

## Production Considerations

1. **Background Sync**: Consider implementing periodic background sync
2. **Conflict Resolution**: Handle cases where same group is modified in both places
3. **Retry Logic**: Implement exponential backoff for failed syncs
4. **User Feedback**: Show sync status indicators in UI
5. **Data Cleanup**: Remove old PENDING groups after successful sync

## Testing Checklist

- [ ] Groups create successfully offline
- [ ] Groups sync to backend when online
- [ ] Banner images upload to Cloudinary
- [ ] Groups fetch from backend correctly
- [ ] App handles network connectivity changes
- [ ] Error messages display appropriately
- [ ] Sync status updates correctly (PENDING → SYNCED)
- [ ] Local SQLite database stores all fields correctly
- [ ] Backend MongoDB receives all group data
- [ ] Authentication works with JWT tokens