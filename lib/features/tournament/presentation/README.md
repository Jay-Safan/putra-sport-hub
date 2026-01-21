# Tournament Feature - Access Control & Organization

## 📁 Directory Structure

```
presentation/
├── shared/              # Students only (viewing/joining)
│   ├── tournament_detail_screen.dart
│   ├── tournament_list_screen.dart
│   ├── join_tournament_screen.dart
│   ├── join_tournament_by_code_screen.dart
│   └── share_tournament_screen.dart
└── student/             # Students only (creating/managing)
    └── create_tournament_screen.dart
```

## 👥 Access Control

### Shared Features (Students Only)
- **Tournament Discovery**: Browse and discover tournaments
- **Tournament Details**: View tournament information, brackets, teams
- **Join Tournament**: Register as a team/participant
- **Join by Code**: Quick join via tournament code
- **Share Tournament**: Share tournament with friends

### Student-Only Features (Creation)
- **Create Tournament**: Students can organize tournaments
- **Tournament Management**: Manage brackets, teams, settings

### Access Restrictions
- **Public Users**: Cannot access tournaments (redirected to home)
- **Admins**: Can view tournaments via admin management screens
- **Student-Referees**: Same access as students (can switch modes)

## 🔄 User Flows

1. **Tournament Discovery** (Students):
   - Home → Tournament Hub → Browse → View Details → Join

2. **Tournament Creation** (Students):
   - Tournament Hub → Create Tournament → Configure → Publish

3. **Tournament Management** (Organizers):
   - My Tournaments → Manage → Update Brackets → Complete

## 💡 Design Decisions

- **Shared folder**: Contains viewing/joining screens (student-only but shared across student types)
- **Student folder**: Contains creation/management screens
- **Access control**: Enforced via route guards (`canAccessStudentFeatures`)
- **Referee Integration**: Tournaments automatically assign referees when registration closes
